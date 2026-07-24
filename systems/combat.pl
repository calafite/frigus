:- module(combat, [
    do_kill/3, do_cast/4, do_pay_bounty/2,
    is_town_npc/1, is_innocent/1, resolve_death/3
]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/combat').
:- use_module('../config/spawn').
:- use_module('prog').
:- use_module('loot').
:- use_module('ai').
:- use_module('status').

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

roll_dice(Min, Max, Val) :- random_between(Min, Max, Val).

get_weapon_tag(Ent, WTag) :-
    ( get_dict(equip, Ent, Eq), is_dict(Eq), get_dict(wpn, Eq, Raw), Raw \== none ->
        to_atom(Raw, WTag)
    ; get_dict(tag, Ent, RawTag) ->
        to_atom(RawTag, WTag)
    ;
        WTag = fists
    ).

chk_dodge(Src, Tgt) :-
    entity:get_stat(Tgt, dex, TDex),
    entity:get_stat(Tgt, luk, TLuk),
    entity:get_stat(Src, dex, SDex),
    ( entity:has_trait(Tgt, elusive) -> Bonus1 = 20 ; entity:has_trait(Tgt, quick) -> Bonus1 = 10 ; Bonus1 = 0 ),
    Rate is max(0, min(65, floor((TDex * 1.2 + TLuk * 0.5) - (SDex * 0.6)) + Bonus1)),
    roll_dice(1, 100, Roll), Roll =< Rate.

calc_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, con, TCon),
    Red is floor(TCon * 0.25),
    Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, fortified, dict{mag: FMag}) -> FMult = (100 - FMag)/100 ; FMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * FMult * DMult)).

calc_spell_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, wis, TWis),
    Red is floor(TWis * 0.25),
    Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, magic_barrier, dict{mag: MMag}) -> MMult = (100 - MMag)/100 ; MMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * MMult * DMult)).

chk_melee_crit(Src, WTag, IsCrit, FinalMult) :-
    entity:get_stat(Src, str, SStr),
    entity:get_stat(Src, luk, SLuk),
    combat_config:wpn_trait(WTag, Trait),
    ( Trait == precision -> Prec = 15 ; Prec = 0 ),
    ( entity:has_trait(Src, feral) -> Feral = 15 ; Feral = 0 ),
    Rate is max(5, min(85, floor(SStr * 0.4 + SLuk * 0.5 + Prec + Feral))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate ->
        IsCrit = true, combat_config:wpn_crit_mult(WTag, BaseMult),
        ( entity:has_trait(Src, celestial) -> FinalMult is BaseMult * 1.5 ; FinalMult = BaseMult )
    ; IsCrit = false, FinalMult = 1.0 ).

chk_spell_crit(Src, IsCrit, Mult) :-
    entity:get_stat(Src, int, SInt), entity:get_stat(Src, wis, SWis), entity:get_stat(Src, luk, SLuk),
    Rate is max(5, min(75, floor(SInt * 0.3 + SWis * 0.3 + SLuk * 0.4))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate -> IsCrit = true, Mult = 1.8 ; IsCrit = false, Mult = 1.0 ).

calc_melee_raw(Src, WTag, RawDmg) :-
    ( combat_config:wpn_dmg(WTag, [dmg(_, Base)|_]) -> true ; Base = 4 ),
    combat_config:wpn_trait(WTag, Trait),
    entity:get_stat(Src, str, Str),
    ( Trait == reliable -> roll_dice(3, 6, Var) ; roll_dice(1, 10, Var) ),
    Raw1 is Base + Var + floor(Str * 0.4),
    ( entity:get_aff(Src, bloodlust, dict{mag: BMag}) -> BMult = (100 + BMag)/100 ; BMult = 1.0 ),
    ( entity:get_aff(Src, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),
    RawDmg is floor(Raw1 * BMult * WMult).

chk_flurry(Src, WTag) :-
    combat_config:wpn_trait(WTag, Trait),
    ( Trait == flurry ; entity:has_trait(Src, quick) ),
    entity:get_stat(Src, dex, SDex), entity:get_stat(Src, luk, SLuk),
    Rate is max(10, min(60, floor(SDex * 0.6 + SLuk * 0.3))),
    roll_dice(1, 100, Roll), Roll =< Rate.

resolve_target(Actor, self, Target) :- !, Target = Actor.
resolve_target(Actor, none, Target) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents), member(Target, Ents),
    ( is_dict(Target, mob) ; is_dict(Target, plyr) ),
    get_dict(id, Target, TId), get_dict(id, Actor, AId), TId \== AId, entity:is_alive(Target), !.
resolve_target(Actor, TgtQuery, Target) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents), member(Target, Ents),
    ( get_dict(id, Target, TgtQuery) ; get_dict(tag, Target, TgtQuery) ), entity:is_alive(Target), !.

is_town_npc(Ent) :-
    get_dict(tag, Ent, RawTag), to_atom(RawTag, Tag), member(Tag, [guard, peasant, merchant, priest, miner]), !.
is_town_npc(Ent) :-
    get_dict(fac, Ent, RawFac), to_atom(RawFac, Fac), member(Fac, [guard, citizen, merchant]), !.

is_innocent(Ent) :- is_town_npc(Ent) ; is_dict(Ent, plyr).
is_crime(Tgt) :- is_innocent(Tgt), ( get_dict(bounty, Tgt, B) -> B =< 0 ; true ).

apply_affliction_list(Ent, [], Ent).
apply_affliction_list(Ent, [Aff|Rest], NEnt) :-
    Aff =.. [AffTag, Dur, Mag],
    entity:apply_aff(Ent, AffTag, Dur, Mag, TmpEnt),
    apply_affliction_list(TmpEnt, Rest, NEnt).

extract_aff_tags([], []).
extract_aff_tags([Aff|Rest], [Tag|TRest]) :- Aff =.. [Tag, _, _], extract_aff_tags(Rest, TRest).

aff_event(TgtId, Tag, aff_applied(TgtId, Tag)).

do_pay_bounty(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
        ( (get_dict(bounty, Actor, B), B > 0) ->
            ( entity:rem_item(Actor, gold, B, A1) ->
                entity:clear_bounty(A1, FinalA),
                world:put_entity(FinalA), world:save_db('world_state.json'),
                clear_local_threats(Id, FinalA),
                Evts = [bounty_paid(Id, B)]
            ; Evts = [error(insufficient_gold_for_bounty(Id, B))] )
        ; Evts = [error(no_bounty_to_pay(Id))] )
    ; Evts = [error(actor_not_found(Id))] ), !.

clear_local_threats(PId, Player) :-
    get_dict(room, Player, Room), world:room_entities(Room, Ents),
    forall(member(M, Ents), ( ( is_dict(M, mob) -> entity:rem_threat(M, PId, NM), world:put_entity(NM) ; true ) )).

do_kill(Id, _TgtQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_kill(Id, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( status:is_cced(Actor, CC) ->
        Evts = [error(cc_prevented(Id, CC))]
    ;
        resolve_target(Actor, TgtQuery, Tgt), !,
        get_dict(id, Tgt, TgtId),
        ( TgtId \== Id ->
            get_weapon_tag(Actor, WTag),
            apply_damage(Id, Actor, Tgt, WTag, Evts)
        ; Evts = [error(cannot_attack_self(Id))] )
    ).
do_kill(Id, TgtQuery, [error(target_not_found(Id, TgtQuery, room(Room)))]) :-
    world:get_entity(Id, Actor), get_dict(room, Actor, Room).

apply_damage(SrcId, SrcEnt, Tgt, WTag, Evts) :-
    get_dict(id, Tgt, TgtId),
    entity:mark_combat(SrcEnt, CbtSrc), entity:mark_combat(Tgt, CbtTgt),
    ( is_crime(CbtTgt), is_dict(CbtSrc, plyr) ->
        BInc is 50, entity:add_bounty(CbtSrc, BInc, NAttacker), world:save_db('world_state.json'),
        CrimeEvts = [bounty_gained(SrcId, BInc)]
    ; CrimeEvts = [], NAttacker = CbtSrc ),
    world:put_entity(NAttacker),

    ( chk_dodge(NAttacker, CbtTgt) ->
        Evts = [dodged(TgtId, SrcId) | CrimeEvts],
        ( (is_dict(CbtTgt, mob), is_dict(NAttacker, plyr)) ->
            entity:add_threat(CbtTgt, SrcId, 5, ThreatTgt), world:put_entity(ThreatTgt)
        ; true )
    ;
        calc_melee_raw(NAttacker, WTag, RawDmg),
        chk_melee_crit(NAttacker, WTag, IsCrit, Mult),
        DmgWithCrit is floor(RawDmg * Mult),
        calc_mitigation(CbtTgt, DmgWithCrit, FinalDmg),

        entity:mod_hp(CbtTgt, -FinalDmg, NTgt),
        get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

        ( IsCrit == true -> HitEvt = crit(SrcId, TgtId, FinalDmg, CurHp, MaxHp)
        ; HitEvt = hit(SrcId, TgtId, FinalDmg, CurHp, MaxHp) ),

        ( entity:is_alive(NTgt) ->
            ( (is_dict(NTgt, mob), is_dict(NAttacker, plyr)) -> entity:add_threat(NTgt, SrcId, FinalDmg, ThreatTgt)
            ; ThreatTgt = NTgt ),
            world:put_entity(ThreatTgt),
            ( chk_flurry(NAttacker, WTag) -> flurry_strike(SrcId, NAttacker, ThreatTgt, FlurryEvts) ; FlurryEvts = [] ),
            ( (is_dict(ThreatTgt, mob), is_dict(NAttacker, plyr)) ->
                ( is_town_npc(ThreatTgt) -> town_brawl_retaliate(ThreatTgt, NAttacker, RetalEvts)
                ; mob_retaliate(ThreatTgt, NAttacker, RetalEvts) )
            ; RetalEvts = [] ),
            append([HitEvt | CrimeEvts], FlurryEvts, TmpEvts),
            append(TmpEvts, RetalEvts, Evts)
        ;
            handle_death(NAttacker, NTgt, DeathEvts),
            ( get_dict(name, NTgt, TgtName) -> true ; TgtName = TgtId ),
            append([HitEvt, dead(TgtId, TgtName) | CrimeEvts], DeathEvts, Evts)
        )
    ).

flurry_strike(SrcId, SrcEnt, Tgt, [flurry(SrcId, TgtId), HitEvt]) :-
    get_dict(id, Tgt, TgtId), get_weapon_tag(SrcEnt, WTag),
    calc_melee_raw(SrcEnt, WTag, RawDmg), calc_mitigation(Tgt, RawDmg, FinalDmg),
    entity:mod_hp(Tgt, -FinalDmg, NTgt), get_dict(hp, NTgt, CurHp),
    ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
    world:put_entity(NTgt),
    HitEvt = hit(SrcId, TgtId, FinalDmg, CurHp, MaxHp).

mob_retaliate(Mob, Player, RetalEvts) :-
    get_dict(id, Mob, MId), get_dict(id, Player, PId), get_weapon_tag(Mob, WTag),
    ( status:is_cced(Mob, _) -> RetalEvts = [] ;
        entity:mark_combat(Mob, CbtMob), entity:mark_combat(Player, CbtPlayer),
        ( chk_dodge(CbtMob, CbtPlayer) ->
            world:put_entity(CbtMob), world:put_entity(CbtPlayer), RetalEvts = [dodged(PId, MId)]
        ;
            calc_melee_raw(CbtMob, WTag, RawDmg), chk_melee_crit(CbtMob, WTag, _, CritMult),
            DmgWithCrit is floor(RawDmg * CritMult), calc_mitigation(CbtPlayer, DmgWithCrit, FinalDmg),
            entity:mod_hp(CbtPlayer, -FinalDmg, NPlayer), get_dict(hp, NPlayer, PCurHp),
            ( get_dict(max_hp, NPlayer, PMaxHp) -> true ; PMaxHp = PCurHp ),
            world:put_entity(CbtMob),
            ( entity:is_alive(NPlayer) ->
                world:put_entity(NPlayer), RetalEvts = [hit(MId, PId, FinalDmg, PCurHp, PMaxHp)]
            ;
                handle_death(CbtMob, NPlayer, DeathEvts), ( get_dict(name, NPlayer, PName) -> true ; PName = PId ),
                RetalEvts = [hit(MId, PId, FinalDmg, 0, PMaxHp), dead(PId, PName) | DeathEvts]
            )
        )
    ).

town_brawl_retaliate(_PrimaryMob, Player, BrawlEvts) :-
    get_dict(room, Player, Room), world:room_entities(Room, Ents),
    findall(Mob, ( member(Mob, Ents), is_dict(Mob, mob), entity:is_alive(Mob), is_town_npc(Mob) ), TownNpcs),
    brawl_attack_all(TownNpcs, Player, BrawlEvts).

brawl_attack_all([], _, []).
brawl_attack_all([Mob|Rest], Player, Evts) :-
    get_dict(id, Player, PId), entity:add_threat(Mob, PId, 10, NMob),
    mob_retaliate(NMob, Player, SingleEvts),
    ( world:get_entity(PId, UpdatedPlayer) -> true ; UpdatedPlayer = Player ),
    brawl_attack_all(Rest, UpdatedPlayer, RestEvts), append(SingleEvts, RestEvts, Evts).

check_affinity(Ent, Sp) :-
    ( combat_config:spell_affinity(Sp, Affs) -> true ; Affs = all ),
    ( Affs == all -> true
    ; get_dict(race, Ent, RawRace), to_atom(RawRace, Race), member(Race, Affs) -> true
    ; get_dict(class, Ent, RawClass), to_atom(RawClass, Class), member(Class, Affs) -> true ).

do_cast(Id, _Sp, _TgtQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_cast(Id, Sp, _TgtQuery, [error(unknown_spell(Id, Sp))]) :- \+ combat_config:spell_type(Sp, _), !.
do_cast(Id, Sp, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( status:is_cced(Actor, CC) ->
        Evts = [error(cc_prevented(Id, CC))]
    ; \+ check_affinity(Actor, Sp) ->
        Evts = [error(spell_affinity_denied(Id, Sp))]
    ;
        combat_config:spell_cost(Sp, Cost),
        get_dict(mp, Actor, Mp),
        ( Mp < Cost -> Evts = [error(insufficient_mp(Id, Sp, mp_available(Mp), mp_required(Cost)))]
        ;
            ( (combat_config:spell_type(Sp, buff) ; combat_config:spell_type(Sp, heal)), (TgtQuery == none ; TgtQuery == self) -> Tgt = Actor
            ; resolve_target(Actor, TgtQuery, Tgt) ), !,
            NMp is Mp - Cost, NActor = Actor.put(mp, NMp), world:put_entity(NActor),

            combat_config:spell_type(Sp, Type),
            ( Type == heal -> execute_heal_spell(Sp, Id, NActor, Tgt, Evts)
            ; Type == buff -> execute_buff_spell(Sp, Id, NActor, Tgt, Evts)
            ; Type == cc   -> execute_damage_spell(Sp, Id, NActor, Tgt, Evts)
            ; execute_damage_spell(Sp, Id, NActor, Tgt, Evts) )
        )
    ).
do_cast(Id, _, TgtQuery, [error(target_not_found(Id, TgtQuery, room(Room)))]) :- world:get_entity(Id, Actor), get_dict(room, Actor, Room).

execute_buff_spell(Sp, Id, Actor, Tgt, Evts) :-
    get_dict(id, Tgt, TgtId),
    ( combat_config:spell_apply_self(Sp, SelfAffs) -> true ; SelfAffs = [] ),
    ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
    apply_affliction_list(Actor, SelfAffs, NAct1),
    ( Actor.id == TgtId -> apply_affliction_list(NAct1, TgtAffs, NActFinal), NTgtFinal = NActFinal
    ; NActFinal = NAct1, apply_affliction_list(Tgt, TgtAffs, NTgtFinal) ),
    world:put_entity(NActFinal),
    ( Actor.id \== TgtId -> world:put_entity(NTgtFinal) ; true ),
    extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, AffEvts),
    Evts = [cast(Id, Sp, TgtId) | AffEvts].

execute_heal_spell(Sp, Id, Actor, Tgt, Evts) :-
    get_dict(id, Tgt, TgtId),
    ( combat_config:spell_dmg(Sp, BaseHeal) -> true ; BaseHeal = 30 ),
    entity:get_stat(Actor, int, Int), HealAmt is BaseHeal + floor(Int * 0.5),
    entity:mod_hp(Tgt, HealAmt, NTgt1),
    ( combat_config:spell_apply_self(Sp, SelfAffs) -> true ; SelfAffs = [] ),
    ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
    apply_affliction_list(Actor, SelfAffs, NAct1),
    ( Actor.id == TgtId -> apply_affliction_list(NTgt1, TgtAffs, NActFinal), NTgtFinal = NActFinal
    ; NActFinal = NAct1, apply_affliction_list(NTgt1, TgtAffs, NTgtFinal) ),
    world:put_entity(NActFinal),
    ( Actor.id \== TgtId -> world:put_entity(NTgtFinal) ; true ),
    get_dict(hp, NTgtFinal, CurHp), ( get_dict(max_hp, NTgtFinal, MaxHp) -> true ; MaxHp = CurHp ),
    extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, AffEvts),
    append([cast(Id, Sp, TgtId), healed(TgtId, HealAmt, CurHp, MaxHp)], AffEvts, Evts).

execute_damage_spell(Sp, Id, Actor, Tgt, Evts) :-
    get_dict(id, Tgt, TgtId),
    ( combat_config:spell_dmg(Sp, BaseDmg) -> true ; BaseDmg = 0 ), !,
    entity:mark_combat(Actor, CbtActor), entity:mark_combat(Tgt, CbtTgt),
    ( is_crime(CbtTgt), is_dict(CbtActor, plyr) ->
        BInc is 50, entity:add_bounty(CbtActor, BInc, NAttacker1), world:save_db('world_state.json'),
        CrimeEvts = [bounty_gained(Id, BInc)]
    ; CrimeEvts = [], NAttacker1 = CbtActor ),
    ( combat_config:spell_apply_self(Sp, SelfAffs) -> true ; SelfAffs = [] ),
    apply_affliction_list(NAttacker1, SelfAffs, NAttacker), world:put_entity(NAttacker),
    get_weapon_tag(NAttacker, WTag), combat_config:wpn_trait(WTag, Trait),
    ( Trait == catalyst -> Mult1 = 1.25 ; Mult1 = 1.0 ),
    entity:get_stat(NAttacker, int, Int),
    ( entity:get_aff(NAttacker, empowered, dict{mag: EMag}) -> EMult = (100 + EMag)/100 ; EMult = 1.0 ),
    ( entity:get_aff(NAttacker, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),
    RawDmg is floor((BaseDmg + floor(Int * 0.5)) * Mult1 * EMult * WMult),
    chk_spell_crit(NAttacker, IsCrit, CritMult), DmgWithCrit is floor(RawDmg * CritMult),
    calc_spell_mitigation(CbtTgt, DmgWithCrit, FinalDmg),
    entity:mod_hp(CbtTgt, -FinalDmg, NTgt1),
    ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
    apply_affliction_list(NTgt1, TgtAffs, NTgt),
    get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
    ( IsCrit == true -> CastEvt = cast_crit(Id, Sp, TgtId) ; CastEvt = cast(Id, Sp, TgtId) ),
    extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, AffEvts),
    ( entity:is_alive(NTgt) ->
        world:put_entity(NTgt),
        ( BaseDmg > 0 -> append([CastEvt, hit(Id, TgtId, FinalDmg, CurHp, MaxHp)], AffEvts, TmpE1) ; append([CastEvt], AffEvts, TmpE1) ),
        append(TmpE1, CrimeEvts, Evts)
    ;
        handle_death(NAttacker, NTgt, DeathEvts), ( get_dict(name, NTgt, TgtName) -> true ; TgtName = TgtId ),
        ( BaseDmg > 0 -> HitList = [hit(Id, TgtId, FinalDmg, 0, MaxHp)] ; HitList = [] ),
        append([CastEvt | HitList], [dead(TgtId, TgtName) | AffEvts], TmpE2),
        append(TmpE2, CrimeEvts, TmpE3), append(TmpE3, DeathEvts, Evts)
    ).

handle_death(SrcEnt, DeadTgt, Evts) :-
    ( get_dict(bounty, DeadTgt, B), B > 0, is_dict(SrcEnt, plyr) ->
        get_dict(id, SrcEnt, SrcId), entity:add_item(SrcEnt, gold, B, NSrc), world:put_entity(NSrc),
        BountyEvts = [bounty_claimed(SrcId, DeadTgt.id, B)]
    ; BountyEvts = [], NSrc = SrcEnt ),
    entity:clear_bounty(DeadTgt, CleanTgt), world:put_entity(CleanTgt), world:save_db('world_state.json'),
    resolve_death(NSrc, CleanTgt, BaseEvts),
    append(BountyEvts, BaseEvts, Evts).

% --- NEW: Leaves the dead player in the room at 0 HP ---
resolve_death(_SrcEnt, DeadTgt, []) :-
    is_dict(DeadTgt, plyr), !,
    Reborn = DeadTgt.put(hp, 0),
    world:put_entity(Reborn).

resolve_death(SrcEnt, DeadMob, Evts) :-
    get_dict(id, DeadMob, MobId), get_dict(room, DeadMob, RoomId),
    world:del_entity(MobId),
    ( is_dict(DeadMob, mob) ->
        get_dict(tag, DeadMob, RawTag), to_atom(RawTag, Tag), spawn_config:mob_xp(Tag, Xp),
        ( SrcEnt \== environment ->
            get_dict(id, SrcEnt, RawSrcId), to_atom(RawSrcId, SrcId), prog:add_xp(SrcId, Xp, XpEvts)
        ; XpEvts = [] ),
        loot:gen_drops(DeadMob, DropEvts),
        ( catch(ai:check_and_spawn_settlement_npc(RoomId), _, fail) -> true ; true ),
        append(XpEvts, DropEvts, Evts)
    ; Evts = [] ).
