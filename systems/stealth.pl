:- module(stealth, [
              check_room_entry_stealth/3,
              do_search/2,
              check_mob_spot_stealthed/3
                   ]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/spawn').
:- use_module('combat/core').
:- use_module('combat/factions').
:- use_module(library(random)).
:- use_module(library(lists)).

get_vis(Ent, Vis) :-
    ( get_dict(race, Ent, RawRace) -> combat_core:to_atom(RawRace, Race)
    ; get_dict(tag, Ent, RawTag) -> combat_core:to_atom(RawTag, Race)
    ; Race = human ),
    ( spawn_config:race_vis(Race, Vis) -> true ; Vis = 60 ).

calc_stealth_score(Ent, Score) :-
    entity:get_stat(Ent, dex, Dex),
    entity:get_stat(Ent, luk, Luk),
    entity:get_stat(Ent, cha, Cha),
    get_vis(Ent, Vis),
    Score is max(1, floor(Dex * 0.5 + Luk * 0.3 + Cha * 0.2 - Vis * 0.2)).

calc_detect_score(Ent, Score) :-
    entity:get_stat(Ent, wis, Wis),
    entity:get_stat(Ent, luk, Luk),
    Score is floor(Wis * 0.5 + Luk * 0.3).

do_search(ActorId, Evts) :-
    world:get_entity(ActorId, Actor),
    get_dict(room, Actor, RoomId),
    combat_core:get_display_name(Actor, ActName),

    entity:get_stat(Actor, int, Int),
    entity:get_stat(Actor, wis, Wis),
    entity:get_stat(Actor, luk, Luk),
    SearchScore is floor(Int * 0.4 + Wis * 0.5 + Luk * 0.2),

    world:room_entities(RoomId, Ents),
    findall(Evt, (
                member(E, Ents),
                get_dict(id, E, EId),
                EId \== ActorId,
                entity:is_alive(E),
                entity:has_aff(E, stealthed),
                calc_stealth_score(E, TargetStealthScore),
                random_between(1, 100, SRoll),
                random_between(1, 100, TRoll),
                ( SRoll + SearchScore >= TRoll + TargetStealthScore ->
                      entity:remove_aff(E, stealthed, NE),
                      world:put_entity(NE),
                      combat_core:get_display_name(E, TargetName),
                      Evt = stealth_revealed(ActName, TargetName)
                ; fail )
                 ), RevealedEvts),

    ( RevealedEvts \== [] ->
          Evts = RevealedEvts
    ; Evts = [search_nothing(ActName)] ).

check_mob_spot_stealthed(Mob, RoomId, Evts) :-
    \+ world:is_safe_room(RoomId),
    world:room_entities(RoomId, Ents),
    calc_detect_score(Mob, MobDS),

    findall(SpottedEvt, (
                member(P, Ents),
                is_dict(P, plyr),
                entity:is_alive(P),
                entity:has_aff(P, stealthed),
                combat_factions:is_enemy(Mob, P),
                calc_stealth_score(P, PSS),
                random_between(1, 100, MRoll),
                random_between(1, 100, PRoll),
                ( MRoll + MobDS + 25 >= PRoll + PSS ->
                      entity:remove_aff(P, stealthed, NP),
                      world:put_entity(NP),
                      combat_core:get_display_name(P, PName),
                      SpottedEvt = stealth_spotted(PName)
                ; fail )
                        ), SpottedEvts),
    Evts = SpottedEvts.

check_room_entry_stealth(ActorId, RoomId, Evts) :-
    world:get_entity(ActorId, Actor),
    ( world:is_safe_room(RoomId) ->
          ( entity:has_aff(Actor, stealthed) ->
                entity:remove_aff(Actor, stealthed, NActor),
                world:put_entity(NActor)
          ; true ),
          Evts = []
    ;
      world:room_entities(RoomId, Ents),

      findall(DS, (
                  member(E, Ents),
                  entity:is_alive(E),
                  combat_factions:is_enemy(Actor, E),
                  calc_detect_score(E, DS)
                  ), DetectScores),

      ( DetectScores \== [] ->
            max_list(DetectScores, MaxDS),
            HasEnemies = true
      ;
        MaxDS = 10,
        HasEnemies = false
      ),

      calc_stealth_score(Actor, SS),
      random_between(1, 100, PRoll),
      random_between(1, 100, ERoll),

      PRes is PRoll + SS,
      ERes is ERoll + MaxDS + 25,

      combat_core:get_display_name(Actor, Name),

      ( PRes >= ERes ->
            entity:apply_aff(Actor, stealthed, 9999, 150, NActor),
            world:put_entity(NActor),
            ( HasEnemies == true ->
                  Evts = [stealth_success(Name)]
            ; Evts = [] )
      ;
        entity:remove_aff(Actor, stealthed, NActor),
        world:put_entity(NActor),
        ( HasEnemies == true ->
              Evts = [stealth_spotted(Name)]
        ; Evts = [] )
      )
    ).
