:- module(move, [step_move/5]).

:- use_module(world).
:- use_module(entity).
:- use_module(map).
:- use_module(visibility).

step_move(W, Id, Dir, NW, [moved(Id, Dir, NRId) | SideEvts]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),

    visibility:resolve_exit(W, A, CurNode, Dir, NRId),
    world:node(W, NRId, NextNode),

    map:can_enter(W, A, NextNode),

    map:on_exit(W, A, CurNode, MidA, ExitEvts),
    entity:room(MidA, NRId, MovedA),
    map:on_enter(W, MovedA, NextNode, FinalA, EnterEvts),

    append(ExitEvts, EnterEvts, SideEvts),

    world:update(W, FinalA, NW).
