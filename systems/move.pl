:- module(move, [do_move/3, resolve_dir/2]).

:- use_module('../core/world').
:- use_module('../worldgen/chunks').
:- use_module('status').

resolve_dir(n, north) :- !.
resolve_dir(s, south) :- !.
resolve_dir(e, east) :- !.
resolve_dir(w, west) :- !.
resolve_dir(u, up) :- !.
resolve_dir(d, down) :- !.
resolve_dir(Dir, Dir).

do_move(Id, _DirQuery, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_move(Id, DirQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( status:is_rooted(Actor, CC) ->
          Evts = [error(cc_prevented(Id, CC))]
    ;
      resolve_dir(DirQuery, Dir),
      world:get_room(Actor.room, CurRoom),
      get_dict(exits, CurRoom, Exits),
      get_dict(Dir, Exits, NextRoomId), !,
      chunks:ensure_chunk(NextRoomId),
      NActor = Actor.put(room, NextRoomId),
      world:put_entity(NActor),
      Evts = [moved(Id, Dir, NextRoomId)]
    ).

do_move(Id, DirQuery, [error(no_exit(Id, DirQuery, available_exits(AvailableExits)))]) :-
    resolve_dir(DirQuery, _),
    world:get_entity(Id, Actor),
    world:get_room(Actor.room, CurRoom),
    get_dict(exits, CurRoom, Exits),
    dict_keys(Exits, AvailableExits).
