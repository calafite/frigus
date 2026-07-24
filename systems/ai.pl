:- module(ai, [do_ai_tick/1, check_and_spawn_settlement_npc/1]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/spawn').
:- use_module('../worldgen/spawn').
:- use_module('combat').
:- use_module('move').
:- use_module(library(random)).
:- use_module(library(lists)).

do_ai_tick(Evts) :-
    world:all_mobs(Mobs),
    process_mobs(Mobs, Evts),
    replenish_settlements.

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

valid_guard_move(Mob, NextRoomId) :-
    get_dict(tag, Mob, RawTag), to_atom(RawTag, guard), !,
    world:get_room(NextRoomId, NextRoom),
    is_settlement_room(NextRoom).
valid_guard_move(_, _).

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

act_mob(Mob, Evts) :-
    is_guard(Mob),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    highest_bounty(Ents, TgtId), !,
    get_dict(id, Mob, MId),
    combat:do_kill(MId, TgtId, Evts),
    world:push_room_events(Room, Evts).

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
    combat:do_kill(MId, TgtId, Evts),
    world:push_room_events(Room, Evts).

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
    combat:do_kill(GuardId, MonId, Evts),
    world:push_room_events(Room, Evts).

act_mob(Mob, Evts) :-
    get_dict(room, Mob, Room),
    \+ is_safe_room(Room),
    is_hostile_mob(Mob),
    world:room_entities(Room, Ents),
    member(P, Ents), is_dict(P, plyr),
    entity:is_alive(P), !,
    get_dict(id, P, PId), get_dict(id, Mob, MId),
    combat:do_kill(MId, PId, Evts),
    world:push_room_events(Room, Evts).

act_mob(Mob, Evts) :-
    random_between(1, 100, R), R =< 20, !,
    get_dict(room, Mob, Room),
    world:get_room(Room, RoomNode),
    get_dict(exits, RoomNode, ExitsDict),
    dict_keys(ExitsDict, Exits), Exits \== [],
    random_member(Dir, Exits),
    get_dict(Dir, ExitsDict, NextRoomId),
    valid_guard_move(Mob, NextRoomId), !,
    get_dict(id, Mob, MId),
    move:do_move(MId, Dir, Evts),
    world:push_room_events(Room, Evts).

replenish_settlements :-
    findall(RId, (world:get_room(RId, Room), is_settlement_room(Room)), SettlementRooms),
    list_to_set(SettlementRooms, UniqueSettlements),
    forall(member(SRoomId, UniqueSettlements), check_and_spawn_settlement_npc(SRoomId)).

check_and_spawn_settlement_npc(RoomId) :-
    world:room_entities(RoomId, Ents),
    include(is_mob_entity, Ents, Mobs),
    include(is_guard, Mobs, Guards),
    length(Mobs, Count),
    length(Guards, GuardCount),
    ( GuardCount =:= 0, Count < 4 ->
        spawn:gen_guard_npc(RoomId, NewNpc),
        world:put_entity(NewNpc),
        get_dict(name, NewNpc, Name),
        world:push_room_event(RoomId, guard_reinforcement(Name))
    ; Count < 4 ->
        random_between(1, 100, Roll),
        ( Roll =< 40 ->
            spawn:gen_town_npc(RoomId, NewNpc),
            world:put_entity(NewNpc),
            get_dict(name, NewNpc, Name),
            world:push_room_event(RoomId, npc_arrived(Name))
        ;
            true
        )
    ;
        true
    ).

is_mob_entity(E) :- is_dict(E, mob).
