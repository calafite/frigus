:- module(stealth, [step_hide/4, strip_stealth/2]).

:- use_module(library(random)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_hide(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    stat(A, dex, Dex),
    skill_val(A, stealth, Lvl),
    random_between(1, 20, Roll),
    Score is Roll + Dex + floor(Lvl * 0.5),
    status:apply_aff(A, aff{type: hidden, val: Score, dur: 9999}, NA, _),
    skill_mod(NA, stealth, 1, FinalA),
    world:update(W, FinalA, NW),
    NLvl is Lvl + 1,
    Evts = [hidden(Id), skill_up(Id, stealth, NLvl)].

strip_stealth(A, NA) :-
    affs(A, Affs),
    ( select(aff{type: hidden, val: _, dur: _}, Affs, R) -> affs(A, R, NA) ; NA = A ).
