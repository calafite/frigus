:- module(combat_death, [
              handle_death/3, resolve_death/3
          ]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('../../worldgen/structures').
:- use_module('../prog').
:- use_module('../loot').
:- use_module('../ai').
:- use_module('../quest').
:- use_module('factions').
:- use_module(library(lists)).

handle_death(SrcEnt, DeadTgt, Evts) :-
    combat_factions:get_proxy_ent(SrcEnt, ProxySrc),
    ( get_dict(bounty, DeadTgt, B), B > 0, is_dict(ProxySrc, plyr) ->
          get_dict(id, ProxySrc, SrcId), entity:add_item(ProxySrc, gold, B, NSrc), world:put_entity(NSrc),
          BountyEvts = [bounty_claimed(SrcId, DeadTgt.id, B)]
    ; BountyEvts = [], NSrc = SrcEnt ),
    entity:clear_bounty(DeadTgt, CleanTgt), world:put_entity(CleanTgt), world:save_db('world_state.json'),
    resolve_death(NSrc, CleanTgt, BaseEvts),
    append(BountyEvts, BaseEvts, Evts).

resolve_death(_SrcEnt, DeadTgt, DropEvts) :-
    is_dict(DeadTgt, plyr), !,
    ( (get_dict(race, DeadTgt, angel) ; (get_dict(equip, DeadTgt, Eq), get_dict(wpn, Eq, seraphs_blade))) ->
          get_dict(room, DeadTgt, RoomId),
          world:gen_id(drop, DropId),
          DropItem = item{id: DropId, tag: seraphs_blade, qty: 1, room: RoomId},
          world:put_entity(DropItem),

          ( get_dict(equip, DeadTgt, Eq1), get_dict(wpn, Eq1, seraphs_blade) ->
                NEq = Eq1.put(wpn, fists),
                TmpP = DeadTgt.put(equip, NEq)
          ; TmpP = DeadTgt ),
          entity:rem_item(TmpP, seraphs_blade, 1, CleanP),

          Reborn = CleanP.put(hp, 0), world:put_entity(Reborn),
          DropEvts = [dropped(DropId, seraphs_blade, 1)]
    ;
      Reborn = DeadTgt.put(hp, 0), world:put_entity(Reborn),
      DropEvts = []
    ).

resolve_death(_SrcEnt, DeadMob, Evts) :-
    get_dict(owner, DeadMob, _), !,
    get_dict(id, DeadMob, MobId),
    world:del_entity(MobId),
    Evts = []. % Summons dissipate immediately without yielding XP/drops

resolve_death(SrcEnt, DeadMob, Evts) :-
    get_dict(id, DeadMob, MobId), get_dict(room, DeadMob, RoomId),
    ( get_dict(struct_id, DeadMob, _) ->
          structures:register_respawn(DeadMob)
    ; true ),
    world:del_entity(MobId),
    ( is_dict(DeadMob, mob) ->
          get_dict(tag, DeadMob, RawTag), combat_core:to_atom(RawTag, Tag), spawn_config:mob_xp(Tag, Xp),
          ( SrcEnt \== environment ->
                get_dict(id, SrcEnt, RawSrcId), combat_core:to_atom(RawSrcId, SrcId),
                prog:add_xp(SrcId, Xp, XpEvts),
                combat_factions:get_proxy_ent(SrcEnt, ProxySrc),
                ( is_dict(ProxySrc, plyr) ->
                    get_dict(id, ProxySrc, PId),
                    % Guarded quest objective tick, ignores failures if quests are malformed
                    ( catch(quest:record_kill(PId, Tag), _, true) -> true ; true )
                ; true )
          ; XpEvts = [] ),
          loot:gen_drops(DeadMob, DropEvts),
          ( catch(ai:check_and_spawn_settlement_npc(RoomId), _, fail) -> true ; true ),
          append(XpEvts, DropEvts, Evts)
    ; Evts = [] ).
