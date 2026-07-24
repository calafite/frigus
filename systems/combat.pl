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
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

roll_dice(Min, Max, Val) :- random_between(Min, Max, Val).

get_weapon_tag(Ent, WTag) :-
    ( get_dict(equip, Ent, Eq), is_dict(Eq), get_dict(wpn, Eq, Raw), Raw \== none -> to_atom(Raw, WTag)
    ; get_dict(tag, Ent, RawTag) -> to_atom(RawTag, WTag)
    ; WTag = fists ).

get_env_mods(Actor, RoomId, Env, MagicMult, CorrMult, MoonMult) :-
    ( world:get_room(RoomId, Room), get_dict(env, Room, REnv) ->
        get_dict(magic, REnv, AmbientMagic), get_dict(corr, REnv, Corruption)
    ; AmbientMagic = 10, Corruption = 0 ),

    MagicMult is 1.0 + (AmbientMagic / 100),
    ( get_dict(race, Actor, Race) -> true ; Race = unknown ),

    ( member(Race, [angel, high_elf]) -> CorrMult is max(0.1, 1.0 - (Corruption / 200))
    ; member(Race, [demon, dark_elf]) -> CorrMult is 1.0 + (Corruption / 100)
    ; CorrMult = 1.0 ),

    ( is_dict(Actor, mob) ->
        get_dict(moon, Env, Moon), moon_mob_mult(Moon, MoonMult)
    ; MoonMult = 1.0 ).

moon_mob_mult(new_moon, 0.8).
moon_mob_mult(crescent, 0.9).
moon_mob_mult(half, 1.0).
moon_mob_mult(gibbous, 1.1).
moon_mob_mult(full_moon, 1.3).

% --- Defense & Mitigation ---
chk_dodge(Src, Tgt) :-
    \+ status:is_rooted(Tgt, _),
    entity:get_stat(Tgt, dex, TDex), entity:get_stat(Tgt, luk, TLuk), entity:get_stat(Src, dex, SDex),
    ( entity:has_trait(Tgt, elusive) -> Bonus1 = 20 ; entity:has_trait(Tgt, quick) -> Bonus1 = 10 ; Bonus1 = 0 ),
    Rate is max(0, min(65, floor((TDex * 1.2 + TLuk * 0.5) - (SDex * 0.6)) + Bonus1)),
    roll_dice(1, 100, Roll), Roll =< Rate.

calc_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, con, TCon), Red is floor(TCon * 0.25), Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, fortified, dict{mag: FMag}) -> FMult = (100 - FMag)/100 ; FMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * FMult * DMult)).

calc_spell_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, wis, TWis), Red is floor(TWis * 0.25), Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, magic_barrier, dict{mag: MMag}) -> MMult = (100 - MMag)/100 ; MMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    ( entity:get_aff(Tgt, fortified, dict{mag: FMag}) -> FMult = (100 - FMag)/100 ; FMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * MMult * DMult * FMult)).

% --- Offense & Output ---
chk_melee_crit(Src, WTag, IsCrit, FinalMult) :-
    entity:get_stat(Src, str, SStr), entity:get_stat(Src, luk, SLuk), combat_config:wpn_trait(WTag, Trait),
    ( Trait == precision -> Prec = 15 ; Prec = 0 ), ( entity:has_trait(Src, feral) -> Feral = 15 ; Feral = 0 ),
    Rate is max(5, min(85, floor(SStr * 0.4 + SLuk * 0.5 + Prec + Feral))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate -> IsCrit = true, combat_config:wpn_crit_mult(WTag, BaseMult),
      ( entity:has_trait(Src, celestial) -> FinalMult is BaseMult * 1.5 ; FinalMult = BaseMult )
    ; IsCrit = false, FinalMult = 1.0 ).

chk_spell_crit(Src, Sp, Tgt, IsCrit, Mult) :-
    is_holy_spell(Sp, Src),
    entity:has_aff(Tgt, marked), !,
    IsCrit = true,
    ( entity:has_trait(Src, celestial) -> Mult = 2.5 ; Mult = 2.0 ).

chk_spell_crit(Src, _Sp, _Tgt, IsCrit, Mult) :-
    entity:get_stat(Src, int, SInt), entity:get_stat(Src, wis, SWis), entity:get_stat(Src, luk, SLuk),
    Rate is max(5, min(75, floor(SInt * 0.3 + SWis * 0.3 + SLuk * 0.4))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate -> IsCrit = true, Mult = 1.8 ; IsCrit = false, Mult = 1.0 ).

is_holy_spell(last_judgement, _).
is_holy_spell(smite, _).
is_holy_spell(divine_retribution, _).
is_holy_spell(_, Src) :- entity:has_trait(Src, celestial).

calc_melee_raw(Src, RoomId, EnvState, WTag, RawDmg) :-
    ( combat_config:wpn_dmg(WTag, [dmg(_, Base)|_]) -> true ; Base = 4 ),
    combat_config:wpn_trait(WTag, Trait), entity:get_stat(Src, str, Str),
    ( Trait == reliable -> roll_dice(3, 6, Var) ; roll_dice(1, 10, Var) ),
    get_env_mods(Src, RoomId, EnvState, _, CorrMult, MoonMult),
    Raw1 is Base + Var + floor(Str * 0.4),
    ( entity:get_aff(Src, bloodlust, dict{mag: BMag}) -> BMult = (100 + BMag)/100 ; BMult = 1.0 ),
    ( entity:get_aff(Src, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),
    RawDmg is floor(Raw1 * BMult * WMult * CorrMult * MoonMult).

chk_flurry(Src, WTag) :-
    combat_config:wpn_trait(WTag, Trait), ( Trait == flurry ; entity:has_trait(Src, quick) ),
    entity:get_stat(Src, dex, SDex), entity:get_stat(Src, luk, SLuk),
    Rate is max(10, min(60, floor(SDex * 0.6 + SLuk * 0.3))),
    roll_dice(1, 100, Roll), Roll =< Rate.

% --- Targeting & Factions ---
is_valid_combat_target(Ent) :- is_dict(Ent, plyr).
is_valid_combat_target(Ent) :- is_dict(Ent, mob).

is_town_npc(Ent) :- get_dict(tag, Ent, RawTag), to_atom(RawTag, Tag), member(Tag, [guard, peasant, merchant, priest, miner]), !.
is_town_npc(Ent) :- get_dict(fac, Ent, RawFac), to_atom(RawFac, Fac), member(Fac, [guard, citizen, merchant]), !.

is_innocent(Ent) :- is_town_npc(Ent) ; is_dict(Ent, plyr).
is_crime(Tgt) :- is_innocent(Tgt), ( get_dict(bounty, Tgt, B) -> B =< 0 ; true ).

is_enemy(Actor, Tgt) :-
    get_dict(id, Actor, AId), get_dict(id, Tgt, TId), AId \== TId,
    ( is_dict(Actor, plyr) -> is_dict(Tgt, mob), \+ is_innocent(Tgt)
    ; is_dict(Tgt, plyr) ; is_town_npc(Tgt) ).

is_friendly(Actor, Tgt) :-
    get_dict(id, Actor, AId), get_dict(id, Tgt, TId),
    ( AId == TId ; is_dict(Actor, plyr), is_dict(Tgt, plyr)
    ; is_dict(Actor, plyr), is_innocent(Tgt)
    ; is_dict(Actor, mob), is_dict(Tgt, mob), \+ is_enemy(Actor, Tgt) ).

resolve_target(Actor, self, Target) :- !, Target = Actor.
resolve_target(Actor, none, Target) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents), member(Target, Ents),
    is_valid_combat_target(Target), get_dict(id, Target, TId), get_dict(id, Actor, AId), TId \== AId, entity:is_alive(Target), !.
resolve_target(Actor, TgtQuery, Target) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents), member(Target, Ents),
    ( get_dict(id, Target, TgtQuery) ; get_dict(tag, Target, TgtQuery) ), entity:is_alive(Target), !.

% --- AoE and Group Targeting logic ---
get_room_targets(Actor, Type, Targets) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents),
    include(entity:is_alive, Ents, AliveEnts),
    filter_targets(Actor, AliveEnts, Type, Targets).

filter_targets(Actor, Ents, area, Targets) :-
    get_dict(id, Actor, AId),
    findall(E, (member(E, Ents), is_valid_combat_target(E), get_dict(id, E, EId), EId \== AId), Targets).
filter_targets(Actor, Ents, group_harm, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_enemy(Actor, E)), Targets).
filter_targets(Actor, Ents, group_heal, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_friendly(Actor, E)), Targets).
filter_targets(Actor, Ents, group_buff, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_friendly(Actor, E)), Targets).

% --- Helpers ---
apply_affliction_list(Ent, [], Ent).
apply_affliction_list(Ent, [Aff|Rest], NEnt) :-
    Aff =.. [AffTag, Dur, Mag], entity:apply_aff(Ent, AffTag, Dur, Mag, TmpEnt),
    apply_affliction_list(TmpEnt, Rest, NEnt).

extract_aff_tags([], []).
extract_aff_tags([Aff|Rest], [Tag|TRest]) :- Aff =.. [Tag, _, _], extract_aff_tags(Rest, TRest).

aff_event(TgtId, Tag, aff_applied(TgtId, Tag)).

do_pay_bounty(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
        ( (get_dict(bounty, Actor, B), B > 0) ->
            ( entity:rem_item(Actor, gold, B, A1) ->
                entity:clear_bounty(A1, FinalA), world:put_entity(FinalA), world:save_db('world_state.json'),
                clear_local_threats(Id, FinalA), Evts = [bounty_paid(Id, B)]
            ; Evts = [error(insufficient_gold_for_bounty(Id, B))] )
        ; Evts = [error(no_bounty_to_pay(Id))] )
    ; Evts = [error(actor_not_found(Id))] ), !.

clear_local_threats(PId, Player) :-
    get_dict(room, Player, Room), world:room_entities(Room, Ents),
    forall(member(M, Ents), ( ( is_dict(M, mob) -> entity:rem_threat(M, PId, NM), world:put_entity(NM) ; true ) )).

% --- Melee Combat Core ---
do_kill(Id, _TgtQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_kill(Id, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, RoomId),
    world:get_room(RoomId, RoomNode),
    ( get_dict(props, RoomNode, Props), member(safe, Props) ->
        Evts = [error(safe_zone(Id))]
    ; status:is_cced(Actor, CC) ->
        Evts = [error(cc_prevented(Id, CC))]
    ; status:is_panicked(Actor, CC) ->
        Evts = [error(cc_prevented(Id, CC))]
    ; resolve_target(Actor, TgtQuery, Tgt), !, get_dict(id, Tgt, TgtId),
      ( TgtId \== Id -> get_weapon_tag(Actor, WTag), apply_damage(Id, Actor, Tgt, WTag, Evts)
      ; Evts = [error(cannot_attack_self(Id))] )
    ).
do_kill(Id, TgtQuery, [error(target_not_found(Id, TgtQuery, room(Room)))]) :- world:get_entity(Id, Actor), get_dict(room, Actor, Room).

apply_damage(SrcId, SrcEnt, Tgt, WTag, Evts) :-
    get_dict(id, Tgt, TgtId), get_dict(room, SrcEnt, RoomId), world:env_state(Env),
    entity:mark_combat(SrcEnt, CbtSrc), entity:mark_combat(Tgt, CbtTgt),
    ( is_crime(CbtTgt), is_dict(CbtSrc, plyr) ->
        BInc is 50, entity:add_bounty(CbtSrc, BInc, NAttacker), world:save_db('world_state.json'), CrimeEvts = [bounty_gained(SrcId, BInc)]
    ; CrimeEvts = [], NAttacker = CbtSrc ),
    world:put_entity(NAttacker),

    ( chk_dodge(NAttacker, CbtTgt) ->
        Evts = [dodged(TgtId, SrcId) | CrimeEvts],
        ( (is_dict(CbtTgt, mob), is_dict(NAttacker, plyr)) -> entity:add_threat(CbtTgt, SrcId, 5, ThreatTgt), world:put_entity(ThreatTgt) ; true )
    ;
        calc_melee_raw(NAttacker, RoomId, Env, WTag, RawDmg), chk_melee_crit(NAttacker, WTag, IsCrit, Mult), DmgWithCrit is floor(RawDmg * Mult),
        calc_mitigation(CbtTgt, DmgWithCrit, FinalDmg),

        entity:mod_hp(CbtTgt, -FinalDmg, NTgt), get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

        ( IsCrit == true -> HitEvt = crit(SrcId, TgtId, FinalDmg, CurHp, MaxHp) ; HitEvt = hit(SrcId, TgtId, FinalDmg, CurHp, MaxHp) ),

        ( entity:get_aff(CbtTgt, thornskin, dict{mag: TMag}) ->
            entity:mod_hp(NAttacker, -TMag, NAttackerThorns),
            get_dict(hp, NAttackerThorns, AttackerHp), ( get_dict(max_hp, NAttackerThorns, AttackerMaxHp) -> true ; AttackerMaxHp = AttackerHp ),
            ThornEvts = [hit(TgtId, SrcId, TMag, AttackerHp, AttackerMaxHp)]
        ; NAttackerThorns = NAttacker, ThornEvts = [] ),
        world:put_entity(NAttackerThorns),

        ( entity:is_alive(NTgt) ->
            ( (is_dict(NTgt, mob), is_dict(NAttackerThorns, plyr)) -> entity:add_threat(NTgt, SrcId, FinalDmg, ThreatTgt) ; ThreatTgt = NTgt ),
            world:put_entity(ThreatTgt),
            ( chk_flurry(NAttackerThorns, WTag) -> flurry_strike(SrcId, NAttackerThorns, ThreatTgt, FlurryEvts) ; FlurryEvts = [] ),
            ( (is_dict(ThreatTgt, mob), is_dict(NAttackerThorns, plyr)) ->
                ( is_town_npc(ThreatTgt) -> town_brawl_retaliate(ThreatTgt, NAttackerThorns, RetalEvts) ; mob_retaliate(ThreatTgt, NAttackerThorns, RetalEvts) )
            ; RetalEvts = [] ),
            append([HitEvt | CrimeEvts], ThornEvts, TmpE1),
            append(TmpE1, FlurryEvts, TmpE2), append(TmpE2, RetalEvts, Evts)
        ;
            handle_death(NAttackerThorns, NTgt, DeathEvts), ( get_dict(name, NTgt, TgtName) -> true ; TgtName = TgtId ),
            append([HitEvt, dead(TgtId, TgtName) | CrimeEvts], ThornEvts, TmpE1),
            append(TmpE1, DeathEvts, Evts)
        )
    ).

flurry_strike(SrcId, SrcEnt, Tgt, [flurry(SrcId, TgtId), HitEvt]) :-
    get_dict(id, Tgt, TgtId), get_weapon_tag(SrcEnt, WTag), get_dict(room, SrcEnt, RoomId), world:env_state(Env),
    calc_melee_raw(SrcEnt, RoomId, Env, WTag, RawDmg), calc_mitigation(Tgt, RawDmg, FinalDmg),
    entity:mod_hp(Tgt, -FinalDmg, NTgt), get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
    world:put_entity(NTgt), HitEvt = hit(SrcId, TgtId, FinalDmg, CurHp, MaxHp).

mob_retaliate(Mob, Player, RetalEvts) :-
    ( \+ entity:is_alive(Player) -> RetalEvts = [] ; status:is_cced(Mob, _) -> RetalEvts = [] ;
        get_dict(id, Mob, MId), get_dict(id, Player, PId), get_weapon_tag(Mob, WTag), get_dict(room, Mob, RoomId), world:env_state(Env),
        entity:mark_combat(Mob, CbtMob), entity:mark_combat(Player, CbtPlayer),
        ( chk_dodge(CbtMob, CbtPlayer) ->
            world:put_entity(CbtMob), world:put_entity(CbtPlayer), RetalEvts = [dodged(PId, MId)]
        ;
            calc_melee_raw(CbtMob, RoomId, Env, WTag, RawDmg), chk_melee_crit(CbtMob, WTag, _, CritMult),
            DmgWithCrit is floor(RawDmg * CritMult), calc_mitigation(CbtPlayer, DmgWithCrit, FinalDmg),
            entity:mod_hp(CbtPlayer, -FinalDmg, NPlayer), get_dict(hp, NPlayer, PCurHp), ( get_dict(max_hp, NPlayer, PMaxHp) -> true ; PMaxHp = PCurHp ),
            world:put_entity(CbtMob),
            ( entity:is_alive(NPlayer) ->
                world:put_entity(NPlayer), RetalEvts = [hit(MId, PId, FinalDmg, PCurHp, PMaxHp)]
            ; handle_death(CbtMob, NPlayer, DeathEvts), ( get_dict(name, NPlayer, PName) -> true ; PName = PId ),
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
    ( entity:is_alive(Player) ->
        get_dict(id, Player, PId), entity:add_threat(Mob, PId, 10, NMob),
        mob_retaliate(NMob, Player, SingleEvts),
        ( world:get_entity(PId, UpdatedPlayer) -> true ; UpdatedPlayer = Player ),
        brawl_attack_all(Rest, UpdatedPlayer, RestEvts), append(SingleEvts, RestEvts, Evts)
    ; Evts = [] ).

% --- Magic & Spell Core ---
check_affinity(Ent, Sp) :-
    ( combat_config:spell_affinity(Sp, Affs) -> true ; Affs = all ),
    ( Affs == all -> true
    ; get_dict(race, Ent, RawRace), to_atom(RawRace, Race), member(Race, Affs) -> true
    ; get_dict(class, Ent, RawClass), to_atom(RawClass, Class), member(Class, Affs) -> true ).

do_cast(Id, Sp, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, RoomId),
    world:get_room(RoomId, RoomNode),
    combat_config:spell_type(Sp, Type),

    ( member(Type, [damage, area, group_harm, cc]), get_dict(props, RoomNode, Props), member(safe, Props) ->
        Evts = [error(safe_zone(Id))]
    ; status:is_cced(Actor, CC) -> Evts = [error(cc_prevented(Id, CC))]
    ; status:is_silenced(Actor, CC) -> Evts = [error(cc_prevented(Id, CC))]
    ; (member(Type, [damage, cc, area, group_harm]), status:is_panicked(Actor, CC)) -> Evts = [error(cc_prevented(Id, CC))]
    ; \+ check_affinity(Actor, Sp) -> Evts = [error(spell_affinity_denied(Id, Sp))]
    ; combat_config:spell_cost(Sp, Cost), get_dict(mp, Actor, Mp),
      ( Mp < Cost -> Evts = [error(insufficient_mp(Id, Sp, mp_available(Mp), mp_required(Cost)))]
      ;
        % Check Mist (Environmental Miss)
        world:env_state(Env), get_dict(mist, Env, Mist), MissChance is floor(Mist / 2),
        roll_dice(1, 100, Roll),
        ( Roll =< MissChance ->
            Evts = [spell_missed(Id, Sp)]
        ;
            resolve_spell_targets(Actor, Type, TgtQuery, Targets),
            ( Targets == [] -> Evts = [error(no_valid_targets(Id, Sp))]
            ; NMp is Mp - Cost, NActor = Actor.put(mp, NMp), world:put_entity(NActor),
              execute_spell_on_targets(Type, Sp, Id, NActor, Targets, Evts)
            )
        )
      )
    ).

resolve_spell_targets(Actor, Type, TgtQuery, Targets) :-
    ( member(Type, [area, group_harm, group_heal, group_buff]) ->
        get_room_targets(Actor, Type, Targets)
    ;
        ( (Type == buff ; Type == heal), (TgtQuery == none ; TgtQuery == self) -> Target = Actor
        ; resolve_target(Actor, TgtQuery, Target) ),
        ( nonvar(Target) -> Targets = [Target] ; Targets = [] )
    ).

execute_spell_on_targets(Type, Sp, Id, Actor, Targets, Evts) :-
    ( combat_config:spell_apply_self(Sp, SelfAffs) -> true ; SelfAffs = [] ),
    apply_affliction_list(Actor, SelfAffs, NAct1), world:put_entity(NAct1),

    ( Type == area -> BaseEvt = [cast_area(Id, Sp)]
    ; member(Type, [group_harm, group_heal, group_buff]) -> BaseEvt = [cast_group(Id, Sp)]
    ; Targets = [SingleTgt|_], get_dict(id, SingleTgt, TgtId), BaseEvt = [cast(Id, Sp, TgtId)]
    ; BaseEvt = [] ),

    world:env_state(Env), get_dict(room, Actor, RoomId),
    get_env_mods(Actor, RoomId, Env, MagicMult, CorrMult, MoonMult),
    Potency is MagicMult * CorrMult * MoonMult,

    process_targets(Type, Sp, Id, Potency, Targets, TgtEvts),
    append(BaseEvt, TgtEvts, Evts).

process_targets(_, _, _, _, [], []).
process_targets(Type, Sp, Id, Potency, [Tgt|Rest], Evts) :-
    world:get_entity(Id, FreshActor), get_dict(id, Tgt, TgtId),
    ( world:get_entity(TgtId, FreshTgt) ->
        process_single_target(Type, Sp, Id, FreshActor, FreshTgt, Potency, TgtEvts),
        process_targets(Type, Sp, Id, Potency, Rest, RestEvts),
        append(TgtEvts, RestEvts, Evts)
    ; process_targets(Type, Sp, Id, Potency, Rest, Evts) ).

process_single_target(Type, Sp, Id, Actor, Tgt, Potency, Evts) :-
    ( member(Type, [damage, cc, area, group_harm]) ->
        get_dict(id, Tgt, TgtId),
        ( combat_config:spell_dmg(Sp, BaseDmg) -> true ; BaseDmg = 0 ),
        entity:mark_combat(Actor, CbtActor), entity:mark_combat(Tgt, CbtTgt),

        ( is_crime(CbtTgt), is_dict(CbtActor, plyr) ->
            BInc is 50, entity:add_bounty(CbtActor, BInc, NAttacker), world:save_db('world_state.json'),
            CrimeEvts = [bounty_gained(Id, BInc)]
        ; CrimeEvts = [], NAttacker = CbtActor ),
        world:put_entity(NAttacker),

        get_weapon_tag(NAttacker, WTag), combat_config:wpn_trait(WTag, Trait),
        ( Trait == catalyst -> Mult1 = 1.25 ; Mult1 = 1.0 ),
        entity:get_stat(NAttacker, int, Int),
        ( entity:get_aff(NAttacker, empowered, dict{mag: EMag}) -> EMult = (100 + EMag)/100 ; EMult = 1.0 ),
        ( entity:get_aff(NAttacker, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),

        RawDmg is floor((BaseDmg + floor(Int * 0.5)) * Mult1 * EMult * WMult * Potency),

        chk_spell_crit(NAttacker, Sp, CbtTgt, IsCrit, CritMult), DmgWithCrit is floor(RawDmg * CritMult),
        calc_spell_mitigation(CbtTgt, DmgWithCrit, FinalDmg),

        entity:mod_hp(CbtTgt, -FinalDmg, NTgt1),
        ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
        apply_affliction_list(NTgt1, TgtAffs, NTgt),
        get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

        ( IsCrit == true -> CritEvt = [cast_crit(Id, Sp, TgtId)] ; CritEvt = [] ),
        ( BaseDmg > 0 -> HitEvt = [hit(Id, TgtId, FinalDmg, CurHp, MaxHp)] ; HitEvt = [] ),
        append(CritEvt, HitEvt, CastEvt),

        extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, AffEvts),

        ( entity:is_alive(NTgt) ->
            world:put_entity(NTgt),
            append(CastEvt, AffEvts, TmpE1), append(TmpE1, CrimeEvts, Evts)
        ; handle_death(NAttacker, NTgt, DeathEvts), ( get_dict(name, NTgt, TgtName) -> true ; TgtName = TgtId ),
          append(CastEvt, [dead(TgtId, TgtName) | AffEvts], TmpE2),
          append(TmpE2, CrimeEvts, TmpE3), append(TmpE3, DeathEvts, Evts) )

    ; member(Type, [heal, group_heal]) ->
        get_dict(id, Tgt, TgtId),
        ( combat_config:spell_dmg(Sp, BaseHeal) -> true ; BaseHeal = 30 ),
        entity:get_stat(Actor, int, Int), HealAmt is floor((BaseHeal + floor(Int * 0.5)) * Potency),
        entity:mod_hp(Tgt, HealAmt, NTgt1),
        ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
        apply_affliction_list(NTgt1, TgtAffs, NTgt), world:put_entity(NTgt),
        get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
        extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, AffEvts),
        append([healed(TgtId, HealAmt, CurHp, MaxHp)], AffEvts, Evts)

    ; member(Type, [buff, group_buff]) ->
        get_dict(id, Tgt, TgtId),
        ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
        apply_affliction_list(Tgt, TgtAffs, NTgt), world:put_entity(NTgt),
        extract_aff_tags(TgtAffs, TgtTags), maplist(aff_event(TgtId), TgtTags, Evts)
    ).

% --- Death Resolving ---
handle_death(SrcEnt, DeadTgt, Evts) :-
    ( get_dict(bounty, DeadTgt, B), B > 0, is_dict(SrcEnt, plyr) ->
        get_dict(id, SrcEnt, SrcId), entity:add_item(SrcEnt, gold, B, NSrc), world:put_entity(NSrc),
        BountyEvts = [bounty_claimed(SrcId, DeadTgt.id, B)]
    ; BountyEvts = [], NSrc = SrcEnt ),
    entity:clear_bounty(DeadTgt, CleanTgt), world:put_entity(CleanTgt), world:save_db('world_state.json'),
    resolve_death(NSrc, CleanTgt, BaseEvts),
    append(BountyEvts, BaseEvts, Evts).

resolve_death(_SrcEnt, DeadTgt, []) :-
    is_dict(DeadTgt, plyr), !,
    Reborn = DeadTgt.put(hp, 0), world:put_entity(Reborn).

resolve_death(SrcEnt, DeadMob, Evts) :-
    get_dict(id, DeadMob, MobId), get_dict(room, DeadMob, RoomId),
    world:del_entity(MobId),
    ( is_dict(DeadMob, mob) ->
        get_dict(tag, DeadMob, RawTag), to_atom(RawTag, Tag), spawn_config:mob_xp(Tag, Xp),
        ( SrcEnt \== environment -> get_dict(id, SrcEnt, RawSrcId), to_atom(RawSrcId, SrcId), prog:add_xp(SrcId, Xp, XpEvts) ; XpEvts = [] ),
        loot:gen_drops(DeadMob, DropEvts),
        ( catch(ai:check_and_spawn_settlement_npc(RoomId), _, fail) -> true ; true ),
        append(XpEvts, DropEvts, Evts)
    ; Evts = [] ).
