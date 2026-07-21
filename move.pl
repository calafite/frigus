:- module(move, [step_move/5]).

:- use_module(world).
:- use_module(entity).
:- use_module(map).

step_move(W, Id, Dir, NW, [moved(Id, Dir, NRId) | SideEvts]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, Node),

    get_dict(Dir, Node.exits, NRId),
    world:node(W, NRId, NextNode),

    map:can_enter(W, A, NextNode),
    entity:room(A, NRId, NA),
    map:on_enter(W, NA, NextNode, NNA, SideEvts),

    world:update(W, NNA, NW).
