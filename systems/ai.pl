:- module(ai, [do_ai_tick/1, check_and_spawn_settlement_npc/1]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../core/events').
:- use_module('../config/spawn').
:- use_module('../worldgen/spawn').
:- use_module('../worldgen/structures').
:- use_module('combat').
:- use_module('move').
:- use_module(library(random)).
:- use_module(library(lists)).

do_ai_tick(Evts) :-
    world:all_mobs(Mobs),
    process_mobs(Mobs, MEvts),
    replenish_settlements,
    structures:tick_respawns(REvts),
    append(MEvts, REvts, Evts).

process_mobs([], []).
process_mobs([Mob|T], Evts) :-
    ( act_mob(Mob, AEvt) -> true ; AEvt = [] ),
    process_mobs(T, REvts),
    append(AEvt, REvts, Evts).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

is_safe_room(RoomId) :-
    world:get_room(RoomId, Room),
    get_dict(props, Room, Props),
    member(safe, Props), !.

is_settlement_room(Room) :-
    ( get_dict(theme, Room, Theme), member(Theme, [village, keep, monastery, town]) ;
      get_dict(props, Room, Props), (member(safe, Props) ; member(landmark, Props)) ;
      get_dict(region, Room, shire) ), !.

is_no_wander(Mob) :-
    ( get_dict(wander, Mob, false)
    ; get_dict(props, Mob, Props), (member(no_wander, Props) ; member(protector, Props))
    ), !.

% Keep town NPCs inside safe settlement boundaries
valid_npc_move(Mob, NextRoomId) :-
    world:get_room(NextRoomId, NextRoom),
    ( is_guard(Mob) ->
        is_settlement_room(NextRoom)
    ; is_town_npc(Mob) ->
        is_settlement_room(NextRoom)
    ;
        true
    ).

is_guard(Mob) :-
    get_dict(tag, Mob, RawTag), to_atom(RawTag, Tag),
    ( Tag == guard ; Tag == protector ), !.
is_guard(Mob) :-
    get_dict(props, Mob, Props),
    member(protector, Props), !.

is_hostile_mob(Mob) :-
    get_dict(tag, Mob, Tag),
    to_atom(Tag, AtomTag),
    spawn_config:is_aggressive(AtomTag).

highest_bounty(Ents, TopId) :-
    findall(B-Id, (
        member(E, Ents),
        get_dict(bounty, E, B), B > 0,
        get_dict(id, E, Id),
        entity:is_alive(E)
    ), Pairs),
    Pairs \== [],
    keysort(Pairs, Sorted),
    reverse(Sorted, [_-TopId|_]).

% Guard attacks criminals
act_mob(Mob, Evts) :-
    is_guard(Mob),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    highest_bounty(Ents, TgtId), !,
    get_dict(id, Mob, MId),
    combat:do_kill(MId, TgtId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Mobs respond to threats
act_mob(Mob, Evts) :-
    get_dict(threats, Mob, Threats),
    dict_keys(Threats, Keys), Keys \== [],
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    member(Tgt, Ents),
    get_dict(id, Tgt, TgtId),
    member(TgtId, Keys),
    entity:is_alive(Tgt), !,
    get_dict(id, Mob, MId),
    combat:do_kill(MId, TgtId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Guard attacks hostile monsters in room
act_mob(Mob, Evts) :-
    is_guard(Mob),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    member(Monster, Ents),
    is_dict(Monster, mob),
    get_dict(id, Monster, MonId),
    get_dict(id, Mob, GuardId),
    MonId \== GuardId,
    is_hostile_mob(Monster),
    entity:is_alive(Monster), !,
    combat:do_kill(GuardId, MonId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Hostile mob attacks player
act_mob(Mob, Evts) :-
    get_dict(room, Mob, Room),
    \+ is_safe_room(Room),
    is_hostile_mob(Mob),
    world:room_entities(Room, Ents),
    member(P, Ents), is_dict(P, plyr),
    entity:is_alive(P), !,
    get_dict(id, P, PId), get_dict(id, Mob, MId),
    combat:do_kill(MId, PId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Controlled random wandering (2% chance per tick, explicitly skipping non-wandering creatures)
act_mob(Mob, Evts) :-
    \+ is_no_wander(Mob),
    random_between(1, 100, R), R =< 2, !,
    get_dict(room, Mob, Room),
    world:get_room(Room, RoomNode),
    get_dict(exits, RoomNode, ExitsDict),
    dict_keys(ExitsDict, Exits), Exits \== [],
    random_member(Dir, Exits),
    get_dict(Dir, ExitsDict, NextRoomId),
    valid_npc_move(Mob, NextRoomId), !,
    get_dict(id, Mob, MId),
    move:do_move(MId, Dir, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Global replenishment with hard settlement cap
replenish_settlements :-
    findall(M, (
        world:db_entity(_, M),
        is_dict(M, mob),
        get_dict(hp, M, Hp), Hp > 0,
        get_dict(room, M, RId),
        world:get_room(RId, RNode),
        is_settlement_room(RNode)
    ), TownMobs),
    length(TownMobs, TotalTownMobs),
    ( TotalTownMobs < 6 ->
        random_between(1, 100, Roll),
        ( Roll =< 5 ->
            spawn:gen_town_npc(square, NewNpc),
            world:put_entity(NewNpc),
            get_dict(name, NewNpc, Name),
            world:push_room_event(square, npc_arrived(Name))
        ; true )
    ; true ).

check_and_spawn_settlement_npc(_) :- true.
