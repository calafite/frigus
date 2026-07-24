:- module(combat, [
    do_kill/3, do_cast/4, do_pay_bounty/2,
    is_town_npc/1, is_innocent/1
]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/combat').
:- use_module('../config/spawn').
:- use_module('prog').
:- use_module('loot').
:- use_module('ai').

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

resolve_target(Actor, self, Target) :- !, Target = Actor.
resolve_target(Actor, none, Target) :-
    get_dict(room, Actor, Room),
    world:room_entities(Room, Ents),
    member(Target, Ents),
    ( is_dict(Target, mob) ; is_dict(Target, plyr) ),
    get_dict(id, Target, TId), get_dict(id, Actor, AId), TId \== AId,
    entity:is_alive(Target), !.
resolve_target(Actor, TgtQuery, Target) :-
    get_dict(room, Actor, Room),
    world:room_entities(Room, Ents),
    member(Target, Ents),
    ( get_dict(id, Target, TgtQuery) ; get_dict(tag, Target, TgtQuery) ),
    entity:is_alive(Target), !.

is_town_npc(Ent) :-
    get_dict(tag, Ent, RawTag), to_atom(RawTag, Tag),
    member(Tag, [guard, peasant, merchant, priest, miner]), !.
is_town_npc(Ent) :-
    get_dict(fac, Ent, RawFac), to_atom(RawFac, Fac),
    member(Fac, [guard, citizen, merchant]), !.

is_innocent(Ent) :-
    is_town_npc(Ent) ; is_dict(Ent, plyr).

is_crime(Tgt) :-
    is_innocent(Tgt),
    ( get_dict(bounty, Tgt, B) -> B =< 0 ; true ).

do_pay_bounty(Id, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(bounty, Actor, B), B > 0 ->
        ( entity:rem_item(Actor, gold, B, A1) ->
            entity:clear_bounty(A1, FinalA),
            world:put_entity(FinalA),
            clear_local_threats(Id, FinalA),
            Evts = [bounty_paid(Id, B)]
        ;
            Evts = [error(insufficient_gold_for_bounty(Id, B))]
        )
    ;
        Evts = [error(no_bounty_to_pay(Id))]
    ).

clear_local_threats(PId, Player) :-
    get_dict(room, Player, Room),
    world:room_entities(Room, Ents),
    forall(member(M, Ents), (
        is_dict(M, mob),
        entity:rem_threat(M, PId, NM),
        world:put_entity(NM)
    )).

do_kill(Id, _TgtQuery, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_kill(Id, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    resolve_target(Actor, TgtQuery, Tgt), !,
    get_dict(id, Tgt, TgtId),
    ( TgtId \== Id ->
        ( get_dict(equip, Actor, Eq), is_dict(Eq), get_dict(wpn, Eq, RawWpn), RawWpn \== none -> to_atom(RawWpn, WTag) ; WTag = fists ),
        ( combat_config:wpn_dmg(WTag, [dmg(_, BaseDmg)|_]) -> true ; BaseDmg = 3 ),
        entity:get_stat(Actor, str, Str),
        Dmg is BaseDmg + floor(Str * 0.5),
        apply_damage(Id, Actor, Tgt, Dmg, Evts)
    ;
        Evts = [error(cannot_attack_self(Id))]
    ).

do_kill(Id, TgtQuery, [error(target_not_found(Id, TgtQuery, room(Room)))]) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, Room).

do_cast(Id, _Sp, _TgtQuery, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_cast(Id, Sp, _TgtQuery, [error(unknown_spell(Id, Sp))]) :-
    \+ combat_config:spell_cost(Sp, _), !.

do_cast(Id, Sp, _TgtQuery, [error(insufficient_mp(Id, Sp, mp_available(Mp), mp_required(Cost)))]) :-
    world:get_entity(Id, Actor),
    combat_config:spell_cost(Sp, Cost),
    get_dict(mp, Actor, Mp),
    Mp < Cost, !.

do_cast(Id, Sp, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    combat_config:spell_cost(Sp, Cost),
    get_dict(mp, Actor, Mp),
    Mp >= Cost,
    ( (Sp == mend, (TgtQuery == none ; TgtQuery == self)) ->
        Tgt = Actor
    ;
        resolve_target(Actor, TgtQuery, Tgt)
    ), !,
    NMp is Mp - Cost,
    NActor = Actor.put(mp, NMp),
    world:put_entity(NActor),
    execute_spell(Sp, Id, NActor, Tgt, Cost, Evts).

do_cast(Id, Sp, TgtQuery, [error(target_not_found(Id, TgtQuery, room(Room)))]) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, Room).

execute_spell(mend, Id, _Actor, Tgt, _Cost, [cast(Id, mend, TgtId), healed(TgtId, HealAmt, CurHp, MaxHp)]) :- !,
    get_dict(id, Tgt, TgtId),
    HealAmt = 30,
    entity:mod_hp(Tgt, HealAmt, NTgt),
    get_dict(hp, NTgt, CurHp),
    ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
    world:put_entity(NTgt).

execute_spell(Sp, Id, Actor, Tgt, _Cost, [cast(Id, Sp, TgtId) | DmgEvts]) :-
    get_dict(id, Tgt, TgtId),
    combat_config:spell_dmg(Sp, BaseDmg), !,
    entity:get_stat(Actor, int, Int),
    Dmg is BaseDmg + floor(Int * 0.5),
    apply_damage(Id, Actor, Tgt, Dmg, DmgEvts).

execute_spell(Sp, Id, _Actor, _Tgt, _Cost, [error(spell_not_implemented(Id, Sp))]).

apply_damage(SrcId, SrcEnt, Tgt, Dmg, Evts) :-
    get_dict(id, Tgt, TgtId),

    ( is_crime(Tgt), is_dict(SrcEnt, plyr) ->
        BInc is Dmg * 5,
        entity:add_bounty(SrcEnt, BInc, NAttacker),
        world:put_entity(NAttacker),
        CrimeEvts = [bounty_gained(SrcId, BInc)]
    ;
        CrimeEvts = [], NAttacker = SrcEnt
    ),

    entity:mod_hp(Tgt, -Dmg, NTgt),
    get_dict(hp, NTgt, CurHp),
    ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

    ( entity:is_alive(NTgt) ->
        ( (is_dict(NTgt, mob), is_dict(NAttacker, plyr)) ->
            entity:add_threat(NTgt, SrcId, Dmg, ThreatTgt)
        ;
            ThreatTgt = NTgt
        ),
        world:put_entity(ThreatTgt),
        ( (is_dict(ThreatTgt, mob), is_dict(NAttacker, plyr)) ->
            ( is_town_npc(ThreatTgt) ->
                town_brawl_retaliate(ThreatTgt, NAttacker, RetalEvts)
            ;
                mob_retaliate(ThreatTgt, NAttacker, RetalEvts)
            )
        ;
            RetalEvts = []
        ),
        append([hit(SrcId, TgtId, Dmg, CurHp, MaxHp) | CrimeEvts], RetalEvts, Evts)
    ;
        handle_death(NAttacker, NTgt, DeathEvts),
        append([hit(SrcId, TgtId, Dmg, 0, MaxHp), dead(TgtId) | CrimeEvts], DeathEvts, Evts)
    ).

town_brawl_retaliate(_PrimaryMob, Player, BrawlEvts) :-
    get_dict(room, Player, Room),
    world:room_entities(Room, Ents),
    findall(Mob, (
        member(Mob, Ents),
        is_dict(Mob, mob),
        entity:is_alive(Mob),
        is_town_npc(Mob)
    ), TownNpcs),
    brawl_attack_all(TownNpcs, Player, BrawlEvts).

brawl_attack_all([], _, []).
brawl_attack_all([Mob|Rest], Player, Evts) :-
    get_dict(id, Player, PId),
    entity:add_threat(Mob, PId, 10, NMob),
    world:put_entity(NMob),
    mob_retaliate(NMob, Player, SingleEvts),
    ( world:get_entity(PId, UpdatedPlayer) -> true ; UpdatedPlayer = Player ),
    brawl_attack_all(Rest, UpdatedPlayer, RestEvts),
    append(SingleEvts, RestEvts, Evts).

get_mob_base_damage(Mob, BaseDmg) :-
    ( get_dict(equip, Mob, Eq), is_dict(Eq), get_dict(wpn, Eq, RawWpn), RawWpn \== none ->
        to_atom(RawWpn, WTag)
    ; get_dict(tag, Mob, RawTag) ->
        to_atom(RawTag, WTag)
    ;
        WTag = fists
    ),
    ( combat_config:wpn_dmg(WTag, [dmg(_, D)|_]) -> BaseDmg = D ; BaseDmg = 4 ).

mob_retaliate(Mob, Player, RetalEvts) :-
    get_dict(id, Mob, MId),
    get_dict(id, Player, PId),
    get_mob_base_damage(Mob, BaseDmg),
    entity:get_stat(Mob, str, Str),
    Dmg is BaseDmg + floor(Str * 0.5),
    entity:mod_hp(Player, -Dmg, NPlayer),
    get_dict(hp, NPlayer, PCurHp),
    ( get_dict(max_hp, NPlayer, PMaxHp) -> true ; PMaxHp = PCurHp ),
    ( entity:is_alive(NPlayer) ->
        world:put_entity(NPlayer),
        RetalEvts = [hit(MId, PId, Dmg, PCurHp, PMaxHp)]
    ;
        handle_death(Mob, NPlayer, DeathEvts),
        RetalEvts = [hit(MId, PId, Dmg, 0, PMaxHp), dead(PId) | DeathEvts]
    ).

handle_death(SrcEnt, DeadTgt, Evts) :-
    ( get_dict(bounty, DeadTgt, B), B > 0, is_dict(SrcEnt, plyr) ->
        get_dict(id, SrcEnt, SrcId),
        entity:add_item(SrcEnt, gold, B, NSrc),
        world:put_entity(NSrc),
        BountyEvts = [bounty_claimed(SrcId, DeadTgt.id, B)]
    ;
        BountyEvts = [], NSrc = SrcEnt
    ),
    entity:clear_bounty(DeadTgt, CleanTgt),
    world:put_entity(CleanTgt),
    resolve_death(NSrc, CleanTgt, BaseEvts),
    append(BountyEvts, BaseEvts, Evts).

resolve_death(_SrcEnt, DeadTgt, [respawned(TgtId, square)]) :-
    is_dict(DeadTgt, plyr), !,
    get_dict(id, DeadTgt, TgtId),
    get_dict(max_hp, DeadTgt, MaxHp),
    get_dict(max_mp, DeadTgt, MaxMp),
    Reborn = DeadTgt.put(hp, MaxHp).put(mp, MaxMp).put(room, square),
    world:put_entity(Reborn).

resolve_death(SrcEnt, DeadMob, Evts) :-
    get_dict(id, DeadMob, MobId),
    get_dict(room, DeadMob, RoomId),
    world:del_entity(MobId),
    ( is_dict(DeadMob, mob) ->
        get_dict(tag, DeadMob, RawTag), to_atom(RawTag, Tag),
        spawn_config:mob_xp(Tag, Xp),
        get_dict(id, SrcEnt, RawSrcId), to_atom(RawSrcId, SrcId),
        prog:add_xp(SrcId, Xp, XpEvts),
        loot:gen_drops(DeadMob, DropEvts),
        ( catch(ai:check_and_spawn_settlement_npc(RoomId), _, fail) -> true ; true ),
        append(XpEvts, DropEvts, Evts)
    ;
        Evts = []
    ).
