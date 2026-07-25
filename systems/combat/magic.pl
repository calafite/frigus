:- module(combat_magic, [
              check_affinity/2, do_cast/4, resolve_spell_targets/4,
              execute_spell_on_targets/6, process_targets/6, process_single_target/7
                        ]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('../../config/combat').
:- use_module('../../worldgen/spawn').
:- use_module('../status').
:- use_module('core').
:- use_module('factions').
:- use_module('death').
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).

check_affinity(Ent, Sp) :-
    ( combat_config:spell_affinity(Sp, Affs) -> true ; Affs = all ),
    ( Affs == all -> true
    ; get_dict(race, Ent, RawRace), combat_core:to_atom(RawRace, Race), member(Race, Affs) -> true
    ; get_dict(class, Ent, RawClass), combat_core:to_atom(RawClass, Class), member(Class, Affs) -> true ).

resolve_spell_targets(Actor, Type, TgtQuery, Targets) :-
    ( Type == summon -> Targets = [Actor]
    ; member(Type, [area, group_harm, group_heal, group_buff]) ->
          combat_factions:get_room_targets(Actor, Type, Targets)
    ;
      ( (Type == buff ; Type == heal), (TgtQuery == none ; TgtQuery == self) -> Targets = [Actor]
      ; combat_factions:resolve_target(Actor, TgtQuery, Target),
        ( Target \== none -> Targets = [Target] ; Targets = [] )
      )
    ).

do_cast(Id, Sp, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( combat_config:spell_type(Sp, Type) ->
          get_dict(room, Actor, RoomId),
          combat_core:get_display_name(Actor, ActName),

          ( status:is_cced(Actor, CC) -> Evts = [error(cc_prevented(Id, CC))]
          ; status:is_silenced(Actor, CC) -> Evts = [error(cc_prevented(Id, CC))]
          ; (member(Type, [damage, cc, area, group_harm]), status:is_panicked(Actor, CC)) -> Evts = [error(cc_prevented(Id, CC))]
          ; \+ check_affinity(Actor, Sp) -> Evts = [error(spell_affinity_denied(Id, Sp))]
          ; Type == summon, combat_core:has_active_summon(Id) -> Evts = [error(already_have_summon(Id))]
          ; ( combat_config:spell_cost(Sp, Cost) -> true ; Cost = 0 ),
            get_dict(mp, Actor, Mp),
            ( Mp < Cost -> Evts = [error(insufficient_mp(Id, Sp, mp_available(Mp), mp_required(Cost)))]
            ;
              world:env_state(Env),
              ( get_dict(mist, Env, Mist) -> true ; Mist = 0 ),
              MissChance is floor(Mist / 2),
              combat_core:roll_dice(1, 100, Roll),
              ( Roll =< MissChance ->
                    % Break stealth even on a spell fizzle/miss
                    ( entity:has_aff(Actor, stealthed) ->
                          entity:remove_aff(Actor, stealthed, NAct2),
                          world:put_entity(NAct2),
                          StealthBreakEvt = [aff_faded(ActName, stealthed)]
                    ; StealthBreakEvt = [] ),
                    append([spell_missed(ActName, Sp)], StealthBreakEvt, Evts)
              ;
                resolve_spell_targets(Actor, Type, TgtQuery, Targets),

                % Enforce Safe Zone Logic: Strip out PvP/Innocent targets from the resolve list
                ( world:is_safe_room(RoomId), member(Type, [damage, cc, area, group_harm]) ->
                      exclude(combat_factions:is_safe_zone_violation(Actor), Targets, ValidTargets)
                ; ValidTargets = Targets ),

                ( ValidTargets == [] ->
                      ( Targets \== [] -> Evts = [error(safe_zone(Id))]
                      ; Evts = [error(no_valid_targets(Id, Sp))] )
                ; NMp is Mp - Cost, NActor = Actor.put(mp, NMp), world:put_entity(NActor),
                  execute_spell_on_targets(Type, Sp, Id, NActor, ValidTargets, Evts)
                )
              )
            )
          )
    ; Evts = [error(unknown_spell(Id, Sp))] ).

execute_spell_on_targets(Type, Sp, Id, Actor, Targets, Evts) :-
    ( combat_config:spell_apply_self(Sp, SelfAffs) -> true ; SelfAffs = [] ),
    combat_core:apply_affliction_list(Actor, SelfAffs, NAct1), world:put_entity(NAct1),
    combat_core:get_display_name(Actor, ActName),
    combat_config:spell_desc(Sp, Desc),

    ( Type == area -> BaseEvt = [cast_area(ActName, Sp, Desc)]
    ; member(Type, [group_harm, group_heal, group_buff]) -> BaseEvt = [cast_group(ActName, Sp, Desc)]
    ; Type == summon ->
          ( combat_config:spell_difficulty(Sp, Diff) -> true ; Diff = 0 ),
          entity:get_stat(Actor, int, Int), entity:get_stat(Actor, wis, Wis),
          combat_core:roll_dice(1, 100, Roll),
          Score is Roll + floor(Int * 1.2) + floor(Wis * 0.8),

          ( Score >= Diff ->
                combat_config:spell_summon_tag(Sp, SumTag),
                get_dict(lvl, Actor, Lvl), get_dict(room, Actor, RoomId),
                spawn:gen_summon(SumTag, Id, Lvl, RoomId, Summon),
                world:put_entity(Summon),
                combat_core:get_display_name(Summon, SumName),
                BaseEvt = [summoned(ActName, Sp, SumName, Desc)]
          ;
            BaseEvt = [summon_failed(ActName, Sp, Desc)]
          )
    ; Targets = [SingleTgt|_], combat_core:get_display_name(SingleTgt, SingleTgtName), BaseEvt = [cast(ActName, Sp, SingleTgtName, Desc)]
    ; BaseEvt = [] ),

    world:env_state(Env), get_dict(room, Actor, RoomId),
    combat_core:get_env_mods(Actor, RoomId, Env, MagicMult, CorrMult, MoonMult),
    Potency is MagicMult * CorrMult * MoonMult,

    ( Type \== summon ->
          process_targets(Type, Sp, Id, Potency, Targets, TgtEvts),

          % Break stealth at the very end of spell execution
          ( entity:has_aff(Actor, stealthed) ->
                world:get_entity(Id, TmpActor),
                entity:remove_aff(TmpActor, stealthed, FinalActor),
                world:put_entity(FinalActor),
                StealthBreakEvt = [aff_faded(ActName, stealthed)]
          ; StealthBreakEvt = [] ),

          append(BaseEvt, TgtEvts, Tmp1),
          append(Tmp1, StealthBreakEvt, Evts)
    ;
      Evts = BaseEvt
    ).

process_targets(_, _, _, _, [], []).
process_targets(Type, Sp, Id, Potency, [Tgt|Rest], Evts) :-
    world:get_entity(Id, FreshActor), get_dict(id, Tgt, TgtId),
    ( world:get_entity(TgtId, FreshTgt) ->
          process_single_target(Type, Sp, Id, FreshActor, FreshTgt, Potency, TgtEvts),
          process_targets(Type, Sp, Id, Potency, Rest, RestEvts),
          append(TgtEvts, RestEvts, Evts)
    ; process_targets(Type, Sp, Id, Potency, Rest, Evts) ).

process_single_target(Type, Sp, Id, Actor, Tgt, Potency, Evts) :-
    combat_core:get_display_name(Actor, ActName),
    combat_core:get_display_name(Tgt, TgtName),

    ( member(Type, [damage, cc, area, group_harm]) ->
          get_dict(id, Tgt, TgtId),
          ( combat_config:spell_dmg(Sp, BaseDmg) -> true ; BaseDmg = 0 ),
          entity:mark_combat(Actor, CbtActor), entity:mark_combat(Tgt, CbtTgt),

          combat_factions:get_proxy_ent(CbtActor, ProxyActor),
          ( combat_factions:is_crime(CbtTgt), is_dict(ProxyActor, plyr) ->
                BInc is 50, entity:add_bounty(ProxyActor, BInc, NAttackerProxy), world:save_db('world_state.json'),
                CrimeEvts = [bounty_gained(Id, BInc)],
                ( get_dict(id, CbtActor, ProxId), get_dict(id, NAttackerProxy, ProxId) -> NAttacker = NAttackerProxy ; NAttacker = CbtActor, world:put_entity(NAttackerProxy) )
          ; CrimeEvts = [], NAttacker = CbtActor ),
          world:put_entity(NAttacker),

          combat_core:get_weapon_tag(NAttacker, WTag),
          ( combat_config:wpn_trait(WTag, catalyst) -> Mult1 = 1.25 ; Mult1 = 1.0 ),
          entity:get_stat(NAttacker, int, Int),
          ( entity:get_aff(NAttacker, empowered, dict{mag: EMag}) -> EMult = (100 + EMag)/100 ; EMult = 1.0 ),
          ( entity:get_aff(NAttacker, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),

          % Apply stealth multiplier
          ( entity:get_aff(NAttacker, stealthed, dict{mag: SMag}) -> SMult = (SMag)/100 ; SMult = 1.0 ),

          RawDmg is floor((BaseDmg + floor(Int * 0.5)) * Mult1 * EMult * WMult * Potency * SMult),

          combat_core:chk_spell_crit(NAttacker, Sp, CbtTgt, IsCrit, CritMult), DmgWithCrit is floor(RawDmg * CritMult),
          combat_core:calc_spell_mitigation(CbtTgt, DmgWithCrit, FinalDmg),

          entity:mod_hp(CbtTgt, -FinalDmg, NTgt1),
          ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
          combat_core:apply_affliction_list(NTgt1, TgtAffs, NTgt),
          get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

          ( IsCrit == true -> CritEvt = [cast_crit(ActName, Sp, TgtName)] ; CritEvt = [] ),
          ( BaseDmg > 0 -> HitEvt = [hit(ActName, TgtName, FinalDmg, CurHp, MaxHp)] ; HitEvt = [] ),
          append(CritEvt, HitEvt, CastEvt),

          combat_core:extract_aff_tags(TgtAffs, TgtTags), maplist(combat_core:aff_event(TgtName), TgtTags, AffEvts),

          ( entity:is_alive(NTgt) ->
                world:put_entity(NTgt),
                append(CastEvt, AffEvts, TmpE1), append(TmpE1, CrimeEvts, Evts)
          ; combat_death:handle_death(NAttacker, NTgt, DeathEvts),
            append(CastEvt, [dead(TgtId, TgtName)  |AffEvts], TmpE2),
            append(TmpE2, CrimeEvts, TmpE3), append(TmpE3, DeathEvts, Evts) )

    ; member(Type, [heal, group_heal]) ->
          ( combat_config:spell_dmg(Sp, BaseHeal) -> true ; BaseHeal = 30 ),
          entity:get_stat(Actor, int, Int), HealAmt is floor((BaseHeal + floor(Int * 0.5)) * Potency),
          entity:mod_hp(Tgt, HealAmt, NTgt1),
          ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
          combat_core:apply_affliction_list(NTgt1, TgtAffs, NTgt), world:put_entity(NTgt),
          get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
          combat_core:extract_aff_tags(TgtAffs, TgtTags), maplist(combat_core:aff_event(TgtName), TgtTags, AffEvts),
          append([healed(TgtName, HealAmt, CurHp, MaxHp)], AffEvts, Evts)

    ; member(Type, [buff, group_buff]) ->
          ( combat_config:spell_apply_tgt(Sp, TgtAffs) -> true ; TgtAffs = [] ),
          combat_core:apply_affliction_list(Tgt, TgtAffs, NTgt), world:put_entity(NTgt),
          combat_core:extract_aff_tags(TgtAffs, TgtTags), maplist(combat_core:aff_event(TgtName), TgtTags, Evts)
    ).
