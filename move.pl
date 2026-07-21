:- module(move, [step_move/5]).

:- use_module(entity).

step_move(S, Id, Dir, NS, [moved(Id, Dir, NRId)]) :-
    has(S, Id, A),
    room(A, RId),
    node(S, RId, Node),
    get_dict(Dir, Node.exits, NRId),
    room(A, NRId, NA),
    put(S, Id, NA, NS).
