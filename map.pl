:- module(map, [can_enter/3, on_enter/5, on_exit/5]).

:- use_module(entity).

cannot_enter(_W, A, N) :- get_dict(req_lvl, N, Lvl), lvl(A, ALvl), ALvl < Lvl.
cannot_enter(_W, A, N) :- get_dict(req_key, N, Key), inv(A, Inv), \+ member(stack{tag: Key}, Inv).

can_enter(W, A, N) :- \+ cannot_enter(W, A, N).

on_exit(_W, A, N, NA, [msg("The mud slows you down.")]) :-
    member(muddy, N.props),
    NA = A, !.
on_exit(_W, A, _N, A, []).

on_enter(_W, A, N, NA, [trap(A.id, Dmg)]) :-
    get_dict(trap, N, Dmg),
    hp(A, Hp),
    NHp is max(0, Hp - Dmg),
    hp(A, NHp, NA), !.
on_enter(_W, A, _N, A, []).
