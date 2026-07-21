:- module(map, [can_enter/3, on_enter/5]).

:- use_module(entity).

cannot_enter(_W, A, N) :- get_dict(req_lvl, N, Lvl), lvl(A, ALvl), ALvl < Lvl.
cannot_enter(_W, A, N) :- get_dict(req_key, N, Key), inv(A, Inv), \+ member(Key, Inv).

can_enter(W, A, N) :- \+ cannot_enter(W, A, N).

on_enter(_W, A, N, NA, [dmg(A.id, Dmg)]) :-
    get_dict(trap, N, Dmg),
    hp(A, Hp),
    NHp is max(0, Hp - Dmg),
    hp(A, NHp, NA), !.

on_enter(_W, A, _N, A, []).
