:- module(stealth, [step_hide/5, strip_stealth/2]).

:- use_module(library(random)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_hide(W, Id, NW, [hidden(Id)]) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    stat(A, dex, Dex),
    random_between(1, 20, Roll),
    Score is Roll + Dex,
    status:apply_aff(A, aff{type: hidden, val: Score, dur: 9999}, NA, _),
    world:update(W, NA, NW).

strip_stealth(A, NA) :-
    affs(A, Affs),
    ( select(aff{type: hidden, val: _, dur: _}, Affs, R) -> affs(A, R, NA) ; NA = A ).
