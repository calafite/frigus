:- module(combat_melee, [
              do_kill/3, apply_damage/5, flurry_strike/4,
              mob_retaliate/3, town_brawl_retaliate/3, brawl_attack_all/3
          ]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('../../config/combat').
:- use_module('../status').
:- use_module('core').
:- use_module('factions').
:- use_module('death').
:- use_module(library(lists)).

do_kill(Id, _TgtQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_kill(Id, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, RoomId),
    ( world:is_safe_room(RoomId) ->
          Evts = [error(safe_zone(Id))]
    ; status:is_cced(Actor, CC) ->
          Evts = [error(cc_prevented(Id, CC))]
    ; status:is_panicked(Actor, CC) ->
          Evts = [error(cc_prevented(Id, CC))]
    ;
      combat_factions:resolve_target(Actor, TgtQuery, Tgt),
      ( Tgt == none ->
          Evts = [error(target_not_found(Id, TgtQuery, room(RoomId)))]
      ; get_dict(id, Tgt, TgtId),
        ( TgtId \== Id ->
              combat_core:get_weapon_tag(Actor, WTag),
              apply_damage(Id, Actor, Tgt, WTag, Evts)
        ; Evts = [error(cannot_attack_self(Id))] )
      )
    ).

apply_damage(SrcId, SrcEnt, Tgt, WTag, Evts) :-
    get_dict(id, Tgt, TgtId), get_dict(room, SrcEnt, RoomId), world:env_state(Env),
    combat_core:get_display_name(SrcEnt, SrcName),
    combat_core:get_display_name(Tgt, TgtName),

    entity:mark_combat(SrcEnt, CbtSrc), entity:mark_combat(Tgt, CbtTgt),

    combat_factions:get_proxy_ent(CbtSrc, ProxySrc),
    ( combat_factions:is_crime(CbtTgt), is_dict(ProxySrc, plyr) ->
          BInc is 50, entity:add_bounty(ProxySrc, BInc, NAttackerProxy), world:save_db('world_state.json'), CrimeEvts = [bounty_gained(SrcId, BInc)],
          ( get_dict(id, CbtSrc, ProxSrcId), get_dict(id, NAttackerProxy, ProxSrcId) -> NAttacker = NAttackerProxy ; NAttacker = CbtSrc, world:put_entity(NAttackerProxy) )
    ; CrimeEvts = [], NAttacker = CbtSrc ),
    world:put_entity(NAttacker),

    ( combat_core:chk_dodge(NAttacker, CbtTgt) ->

          % Still break stealth on dodge
          ( entity:has_aff(NAttacker, stealthed) ->
              entity:remove_aff(NAttacker, stealthed, NAttacker2),
              world:put_entity(NAttacker2),
              StealthBreakEvt = [aff_faded(SrcName, stealthed)]
          ; StealthBreakEvt = [] ),

          append([dodged(TgtName, SrcName)], CrimeEvts, TmpE),
          append(TmpE, StealthBreakEvt, Evts),
          ( (is_dict(CbtTgt, mob), is_dict(ProxySrc, plyr)) -> entity:add_threat(CbtTgt, SrcId, 5, ThreatTgt), world:put_entity(ThreatTgt) ; true )
    ;
      combat_core:calc_melee_raw(NAttacker, RoomId, Env, WTag, RawDmg), combat_core:chk_melee_crit(NAttacker, WTag, IsCrit, Mult), DmgWithCrit is floor(RawDmg * Mult),
      combat_core:calc_mitigation(CbtTgt, DmgWithCrit, FinalDmg),

      % Break stealth after the attack is fully calculated
      ( entity:has_aff(NAttacker, stealthed) ->
          entity:remove_aff(NAttacker, stealthed, NAttacker2),
          StealthBreakEvt = [aff_faded(SrcName, stealthed)]
      ; NAttacker2 = NAttacker, StealthBreakEvt = [] ),

      entity:mod_hp(CbtTgt, -FinalDmg, NTgt), get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),

      ( IsCrit == true -> HitEvt = crit(SrcName, TgtName, FinalDmg, CurHp, MaxHp) ; HitEvt = hit(SrcName, TgtName, FinalDmg, CurHp, MaxHp) ),

      ( entity:get_aff(CbtTgt, thornskin, dict{mag: TMag}) ->
            entity:mod_hp(NAttacker2, -TMag, NAttackerThorns),
            get_dict(hp, NAttackerThorns, AttackerHp), ( get_dict(max_hp, NAttackerThorns, AttackerMaxHp) -> true ; AttackerMaxHp = AttackerHp ),
            ThornEvts = [hit(TgtName, SrcName, TMag, AttackerHp, AttackerMaxHp)]
      ; NAttackerThorns = NAttacker2, ThornEvts = [] ),
      world:put_entity(NAttackerThorns),

      ( entity:is_alive(NTgt) ->
            ( (is_dict(NTgt, mob), is_dict(ProxySrc, plyr)) -> entity:add_threat(NTgt, SrcId, FinalDmg, ThreatTgt) ; ThreatTgt = NTgt ),
            world:put_entity(ThreatTgt),
            ( combat_core:chk_flurry(NAttackerThorns, WTag) -> flurry_strike(SrcId, NAttackerThorns, ThreatTgt, FlurryEvts) ; FlurryEvts = [] ),
            ( (is_dict(ThreatTgt, mob), is_dict(ProxySrc, plyr)) ->
                  ( combat_factions:is_town_npc(ThreatTgt) -> town_brawl_retaliate(ThreatTgt, NAttackerThorns, RetalEvts) ; mob_retaliate(ThreatTgt, NAttackerThorns, RetalEvts) )
            ; RetalEvts = [] ),
            append([HitEvt  |CrimeEvts], ThornEvts, TmpE1),
            append(TmpE1, FlurryEvts, TmpE2), append(TmpE2, RetalEvts, TmpE3),
            append(TmpE3, StealthBreakEvt, Evts)
      ;
        combat_death:handle_death(NAttackerThorns, NTgt, DeathEvts),
        append([HitEvt, dead(TgtId, TgtName)  |CrimeEvts], ThornEvts, TmpE1),
        append(TmpE1, StealthBreakEvt, TmpE2),
        append(TmpE2, DeathEvts, Evts)
      )
    ).

flurry_strike(_SrcId, SrcEnt, Tgt, [flurry(SrcName, TgtName), HitEvt]) :-
    combat_core:get_display_name(SrcEnt, SrcName), combat_core:get_display_name(Tgt, TgtName),
    combat_core:get_weapon_tag(SrcEnt, WTag), get_dict(room, SrcEnt, RoomId), world:env_state(Env),
    combat_core:calc_melee_raw(SrcEnt, RoomId, Env, WTag, RawDmg), combat_core:calc_mitigation(Tgt, RawDmg, FinalDmg),
    entity:mod_hp(Tgt, -FinalDmg, NTgt), get_dict(hp, NTgt, CurHp), ( get_dict(max_hp, NTgt, MaxHp) -> true ; MaxHp = CurHp ),
    world:put_entity(NTgt), HitEvt = hit(SrcName, TgtName, FinalDmg, CurHp, MaxHp).

mob_retaliate(Mob, Player, RetalEvts) :-
    get_dict(room, Mob, RoomId),
    ( world:is_safe_room(RoomId) -> RetalEvts = []
    ; \+ entity:is_alive(Player) -> RetalEvts = []
    ; status:is_cced(Mob, _) -> RetalEvts = []
    ;
      get_dict(id, Player, PId), combat_core:get_weapon_tag(Mob, WTag), world:env_state(Env),
      combat_core:get_display_name(Mob, MName), combat_core:get_display_name(Player, PName),

      entity:mark_combat(Mob, CbtMob), entity:mark_combat(Player, CbtPlayer),
      ( combat_core:chk_dodge(CbtMob, CbtPlayer) ->
            world:put_entity(CbtMob), world:put_entity(CbtPlayer), RetalEvts = [dodged(PName, MName)]
      ;
        combat_core:calc_melee_raw(CbtMob, RoomId, Env, WTag, RawDmg), combat_core:chk_melee_crit(CbtMob, WTag, _, CritMult),
        DmgWithCrit is floor(RawDmg * CritMult), combat_core:calc_mitigation(CbtPlayer, DmgWithCrit, FinalDmg),
        entity:mod_hp(CbtPlayer, -FinalDmg, NPlayer), get_dict(hp, NPlayer, PCurHp), ( get_dict(max_hp, NPlayer, PMaxHp) -> true ; PMaxHp = PCurHp ),
        world:put_entity(CbtMob),
        ( entity:is_alive(NPlayer) ->
              world:put_entity(NPlayer), RetalEvts = [hit(MName, PName, FinalDmg, PCurHp, PMaxHp)]
        ; combat_death:handle_death(CbtMob, NPlayer, DeathEvts),
          RetalEvts = [hit(MName, PName, FinalDmg, 0, PMaxHp), dead(PId, PName)  |DeathEvts]
        )
      )
    ).

town_brawl_retaliate(_PrimaryMob, Player, BrawlEvts) :-
    get_dict(room, Player, Room),
    ( world:is_safe_room(Room) -> BrawlEvts = []
    ;
      world:room_entities(Room, Ents),
      findall(Mob, ( member(Mob, Ents), is_dict(Mob, mob), entity:is_alive(Mob), combat_factions:is_town_npc(Mob) ), TownNpcs),
      brawl_attack_all(TownNpcs, Player, BrawlEvts)
    ).

brawl_attack_all([], _, []).
brawl_attack_all([Mob|Rest], Player, Evts) :-
    ( entity:is_alive(Player) ->
          get_dict(id, Player, PId), entity:add_threat(Mob, PId, 10, NMob),
          mob_retaliate(NMob, Player, SingleEvts),
          ( world:get_entity(PId, UpdatedPlayer) -> true ; UpdatedPlayer = Player ),
          brawl_attack_all(Rest, UpdatedPlayer, RestEvts), append(SingleEvts, RestEvts, Evts)
    ; Evts = [] ).
