:- module(world, [
    get_entity/2, put_entity/1, del_entity/1,
    get_room/2, put_room/1, del_room/1,
    env_state/1, put_env/1,
    room_entities/2, gen_id/2, all_mobs/1,
    push_room_event/2, push_room_events/2, pop_room_events/2,
    clear_db/0, save_db/1, load_db/1,
    get_bounty_leaderboard/2
]).

:- use_module(library(json)).
:- use_module(library(random)).

:- dynamic db_entity/2.
:- dynamic db_room/2.
:- dynamic db_room_event/2.
:- dynamic db_bounty_index/2.
:- dynamic db_env/1.

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

clean_entity(Ent, CleanEnt) :-
    is_dict(Ent), !,
    get_dict(id, Ent, RawId), to_atom(RawId, Id),
    ( get_dict(room, Ent, RawRoom) -> to_atom(RawRoom, Room) ; Room = square ),
    ( get_dict(tag, Ent, RawTag) -> to_atom(RawTag, Tag) ; Tag = unknown ),
    determine_kind(Ent, Kind),
    dict_pairs(Ent, _, Pairs),
    dict_pairs(TaggedEnt, Kind, Pairs),
    CleanEnt = TaggedEnt.put(id, Id).put(room, Room).put(tag, Tag).
clean_entity(Ent, Ent).

determine_kind(Ent, plyr) :-
    ( is_dict(Ent, plyr) ; get_dict(tag, Ent, player) ; get_dict(class, Ent, _) ), !.
determine_kind(Ent, item) :-
    ( is_dict(Ent, item) ; get_dict(qty, Ent, _) ), !.
determine_kind(_, mob).

clean_room(Room, CleanRoom) :-
    is_dict(Room), !,
    get_dict(id, Room, RawId), to_atom(RawId, Id),
    ( get_dict(exits, Room, ExitsDict), is_dict(ExitsDict) ->
        dict_pairs(ExitsDict, Tag, Pairs),
        clean_exit_pairs(Pairs, CleanPairs),
        dict_pairs(CleanExits, Tag, CleanPairs)
    ; CleanExits = dict{} ),
    CleanRoom = Room.put(id, Id).put(exits, CleanExits).
clean_room(Room, Room).

clean_exit_pairs([], []).
clean_exit_pairs([Dir-RawDest|T], [Dir-Dest|NT]) :-
    to_atom(RawDest, Dest),
    clean_exit_pairs(T, NT).

gen_id(Prefix, Id) :-
    random_between(1000000, 9999999, Rnd),
    atomic_list_concat([Prefix, '_', Rnd], Id).

get_entity(RawId, Ent) :-
    to_atom(RawId, Id),
    db_entity(Id, Ent), !.

put_entity(Ent) :-
    clean_entity(Ent, CleanEnt),
    get_dict(id, CleanEnt, Id),
    retractall(db_entity(Id, _)),
    assertz(db_entity(Id, CleanEnt)),
    retractall(db_bounty_index(Id, _)),
    ( get_dict(bounty, CleanEnt, B), B > 0 ->
        assertz(db_bounty_index(Id, B))
    ; true ).

del_entity(RawId) :-
    to_atom(RawId, Id),
    retractall(db_entity(Id, _)),
    retractall(db_bounty_index(Id, _)).

get_room(RawId, Room) :-
    to_atom(RawId, Id),
    db_room(Id, Room), !.

put_room(Room) :-
    clean_room(Room, CleanRoom),
    get_dict(id, CleanRoom, Id),
    retractall(db_room(Id, _)),
    assertz(db_room(Id, CleanRoom)).

del_room(RawId) :-
    to_atom(RawId, Id),
    retractall(db_room(Id, _)).

env_state(Env) :- db_env(Env), !.
env_state(env{time: 480, weather: clear}).

put_env(Env) :-
    retractall(db_env(_)),
    assertz(db_env(Env)).

room_entities(RawRoomId, Ents) :-
    to_atom(RawRoomId, RoomId),
    findall(E, (db_entity(_, E), get_dict(room, E, RoomId)), Ents).

all_mobs(Mobs) :-
    findall(M, (db_entity(_, M), is_dict(M, mob), get_dict(hp, M, Hp), Hp > 0), Mobs).

push_room_event(RawRoomId, Event) :-
    to_atom(RawRoomId, RoomId),
    assertz(db_room_event(RoomId, Event)).

push_room_events(_, []) :- !.
push_room_events(RoomId, [E|Es]) :-
    push_room_event(RoomId, E),
    push_room_events(RoomId, Es).

pop_room_events(RawRoomId, Events) :-
    to_atom(RawRoomId, RoomId),
    findall(E, db_room_event(RoomId, E), Events),
    retractall(db_room_event(RoomId, _)).

clear_db :-
    retractall(db_entity(_, _)),
    retractall(db_room(_, _)),
    retractall(db_room_event(_, _)),
    retractall(db_bounty_index(_, _)),
    retractall(db_env(_)).

save_db(Filename) :-
    findall(E, db_entity(_, E), Ents),
    findall(R, db_room(_, R), Rooms),
    env_state(Env),
    State = json{entities: Ents, rooms: Rooms, env: Env},
    setup_call_cleanup(
        open(Filename, write, Stream),
        json_write_dict(Stream, State, [width(0)]),
        close(Stream)
    ).

load_db(Filename) :-
    exists_file(Filename),
    catch(
        setup_call_cleanup(
            open(Filename, read, Stream),
            json_read_dict(Stream, State),
            close(Stream)
        ),
        _,
        fail
    ),
    clear_db,
    ( get_dict(entities, State, Ents) -> forall(member(E, Ents), put_entity(E)) ; true ),
    ( get_dict(rooms, State, Rooms) -> forall(member(R, Rooms), put_room(R)) ; true ),
    ( get_dict(env, State, Env) -> put_env(Env) ; put_env(env{time: 480, weather: clear}) ).

take(0, _, []) :- !.
take(_, [], []) :- !.
take(N, [H|T], [H|Rest]) :-
    N > 0, N1 is N - 1,
    take(N1, T, Rest).

get_bounty_leaderboard(Limit, Leaderboard) :-
    findall(B-Id, db_bounty_index(Id, B), Pairs),
    keysort(Pairs, Sorted),
    reverse(Sorted, Desc),
    take(Limit, Desc, RawList),
    maplist(format_bounty_entry, RawList, Leaderboard).

format_bounty_entry(Bounty-Id, dict{id: Id, name: Name, bounty: Bounty}) :-
    ( db_entity(Id, Ent), get_dict(name, Ent, Name) -> true ; Name = Id ).
