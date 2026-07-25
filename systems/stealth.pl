:- module(stealth, [
    check_room_entry_stealth/3
]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/spawn').
:- use_module('combat/core').
:- use_module('combat/factions').
:- use_module(library(random)).
:- use_module(library(lists)).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

% Entity's inherent visibility
get_vis(Ent, Vis) :-
    ( get_dict(race, Ent, RawRace) -> to_atom(RawRace, Race)
    ; get_dict(tag, Ent, RawTag) -> to_atom(RawTag, Race)
    ; Race = human ),
    ( spawn_config:race_vis(Race, Vis) -> true ; Vis = 60 ).

% Calculate player's stealth score
% Dexterity + Luck + Charisma oppose the Base Visibility of the race.
calc_stealth_score(Ent, Score) :-
    entity:get_stat(Ent, dex, Dex),
    entity:get_stat(Ent, luk, Luk),
    entity:get_stat(Ent, cha, Cha),
    get_vis(Ent, Vis),
    Score is max(1, floor(Dex * 1.5 + Luk * 1.0 + Cha * 0.5 - Vis * 0.5)).

% Calculate enemy's detection score based primarily on Wisdom
calc_detect_score(Ent, Score) :-
    entity:get_stat(Ent, wis, Wis),
    entity:get_stat(Ent, luk, Luk),
    Score is floor(Wis * 1.5 + Luk * 0.5).

% Executed when an entity enters a room
check_room_entry_stealth(ActorId, RoomId, Evts) :-
    world:get_entity(ActorId, Actor),
    ( world:is_safe_room(RoomId) ->
        % Instantly strip stealth in safe zones; no roll occurs.
        ( entity:has_aff(Actor, stealthed) ->
            entity:remove_aff(Actor, stealthed, NActor),
            world:put_entity(NActor)
        ; true ),
        Evts = []
    ;
        world:room_entities(RoomId, Ents),

        % Find all hostile enemies and their detection scores
        findall(DS, (
            member(E, Ents),
            entity:is_alive(E),
            combat_factions:is_enemy(Actor, E),
            calc_detect_score(E, DS)
        ), DetectScores),

        % The DC is the highest Wisdom/Detection score among enemies present
        ( DetectScores \== [] ->
            max_list(DetectScores, MaxDS),
            HasEnemies = true
        ;
            MaxDS = 10,
            HasEnemies = false
        ),

        calc_stealth_score(Actor, SS),
        random_between(1, 20, PRoll),
        random_between(1, 20, ERoll),

        PRes is PRoll + SS,
        ERes is ERoll + MaxDS,

        combat_core:get_display_name(Actor, Name),

        ( PRes >= ERes ->
            % 150 = 150% damage multiplier on the first strike from stealth.
            % 9999 duration means it lasts until an attack breaks it.
            entity:apply_aff(Actor, stealthed, 9999, 150, NActor),
            world:put_entity(NActor),
            ( HasEnemies == true ->
                Evts = [stealth_success(Name)]
            ; Evts = [] ) % Silently stealth if no enemies are around to avoid spam
        ;
            % Player failed the stealth check.
            entity:remove_aff(Actor, stealthed, NActor),
            world:put_entity(NActor),
            ( HasEnemies == true ->
                Evts = [stealth_spotted(Name)]
            ; Evts = [] )
        )
    ).
