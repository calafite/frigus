:- module(move, [
              do_move/3,
              resolve_dir/2,
              do_start_walk/3,
              do_cancel_walk/2,
              do_tick_walk/2
                ]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../worldgen/chunks').
:- use_module('status').
:- use_module('combat/core').
:- use_module(library(lists)).

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
      OldRoomId = Actor.room,
      NActor = Actor.put(room, NextRoomId),
      world:put_entity(NActor),

      ( get_dict(name, Actor, DisplayName) -> true
      ; (is_dict(Actor, plyr) ; get_dict(tag, Actor, player)) -> get_dict(id, Actor, DisplayName)
      ; get_dict(tag, Actor, DisplayName) -> true
      ; DisplayName = Id ),

      move_summons(Id, OldRoomId, NextRoomId, Dir, SummonEvts),

      BaseEvt = moved(Id, Dir, NextRoomId, DisplayName),
      append([BaseEvt], SummonEvts, Evts)
    ).

do_move(Id, DirQuery, [error(no_exit(Id, DirQuery, available_exits(AvailableExits)))]) :-
    resolve_dir(DirQuery, _),
    world:get_entity(Id, Actor),
    world:get_room(Actor.room, CurRoom),
    get_dict(exits, CurRoom, Exits),
    dict_keys(Exits, AvailableExits).

% ---------------------------------------------------------
% Summon Following Mechanics
% ---------------------------------------------------------

move_summons(OwnerId, OldRoomId, NextRoomId, Dir, SummonEvts) :-
    world:room_entities(OldRoomId, Ents),
    findall(M, (
                member(M, Ents),
                is_dict(M, mob),
                get_dict(owner, M, OwnerId),
                entity:is_alive(M),
                \+ status:is_rooted(M, _)
               ), Summons),
    process_summon_moves(Summons, NextRoomId, Dir, SummonEvts).

process_summon_moves([], _, _, []).
process_summon_moves([Summon|Rest], NextRoomId, Dir, [moved(SummonId, Dir, NextRoomId, DisplayName)|RestEvts]) :-
    get_dict(id, Summon, SummonId),
    combat_core:get_display_name(Summon, DisplayName),
    NSummon = Summon.put(room, NextRoomId),
    world:put_entity(NSummon),
    process_summon_moves(Rest, NextRoomId, Dir, RestEvts).

% ---------------------------------------------------------
% Auto-walk Systems
% ---------------------------------------------------------

do_start_walk(Id, _DestQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_start_walk(Id, DestQuery, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, RoomId),
    ( \+ is_wild_room(RoomId) ->
          Evts = [error(not_in_wild(Id))]
    ; \+ is_wild_room(DestQuery) ->
          Evts = [error(invalid_walk_target(Id))]
    ; RoomId == DestQuery ->
          Evts = [error(already_at_destination(Id))]
    ;
      NActor = Actor.put(walk_target, DestQuery),
      world:put_entity(NActor),
      Evts = [walk_started(Id, DestQuery)]
    ).

do_cancel_walk(Id, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(walk_target, Actor, _) ->
          del_dict(walk_target, Actor, _, NActor),
          world:put_entity(NActor),
          Evts = [walk_cancelled(Id)]
    ; Evts = [error(not_walking(Id))] ).

do_tick_walk(Id, Evts) :-
    world:get_entity(Id, Act),
    ( get_dict(walk_target, Act, DestId) ->
          get_dict(room, Act, RoomId),
          ( RoomId == DestId ->
                del_dict(walk_target, Act, _, NAct),
                world:put_entity(NAct),
                Evts = [walk_completed(Id, DestId)]
          ; status:is_rooted(Act, CC) ->
                del_dict(walk_target, Act, _, NAct),
                world:put_entity(NAct),
                Evts = [walk_cancelled(Id), error(cc_prevented(Id, CC))]
          ; \+ is_wild_room(RoomId) ->
                del_dict(walk_target, Act, _, NAct),
                world:put_entity(NAct),
                Evts = [walk_cancelled(Id), error(not_in_wild(Id))]
          ; \+ is_wild_room(DestId) ->
                del_dict(walk_target, Act, _, NAct),
                world:put_entity(NAct),
                Evts = [walk_cancelled(Id), error(invalid_walk_target(Id))]
          ; calc_next_step(RoomId, DestId, Dir) ->
                do_move(Id, Dir, MoveEvts),
                ( member(error(_), MoveEvts) ->
                      del_dict(walk_target, Act, _, NAct),
                      world:put_entity(NAct),
                      Evts = [walk_cancelled(Id)  |MoveEvts]
                ;
                  world:get_entity(Id, TmpAct),
                  get_dict(room, TmpAct, NewRoomId),
                  ( NewRoomId == DestId ->
                        del_dict(walk_target, TmpAct, _, FinalAct),
                        world:put_entity(FinalAct),
                        CompEvts = [walk_completed(Id, DestId)],
                        append(MoveEvts, CompEvts, Evts)
                  ; Evts = MoveEvts )
                )
          ;
            del_dict(walk_target, Act, _, NAct),
            world:put_entity(NAct),
            Evts = [walk_cancelled(Id)]
          )
    ; Evts = [] ).

is_wild_room(RoomId) :-
    atom(RoomId),
    atomic_list_concat(['cell', _, _, _], '_', RoomId).

calc_next_step(Cur, Dest, Dir) :-
    atomic_list_concat(['cell', CXStr, CYStr, CZStr], '_', Cur),
    atomic_list_concat(['cell', DXStr, DYStr, DZStr], '_', Dest),
    atom_number(CXStr, CX), atom_number(CYStr, CY), atom_number(CZStr, CZ),
    atom_number(DXStr, DX), atom_number(DYStr, DY), atom_number(DZStr, DZ),
    ( CX < DX -> Dir = east
    ; CX > DX -> Dir = west
    ; CY < DY -> Dir = north
    ; CY > DY -> Dir = south
    ; CZ < DZ -> Dir = up
    ; CZ > DZ -> Dir = down
    ; fail ).
