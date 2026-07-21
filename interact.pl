:- module(interact, [step_pull/5, step_disarm/4]).

:- use_module(library(random)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_pull(W, Id, Sw, NW, [pulled(Id, Sw)]) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    room(A, RId),
    world:node(W, RId, N),
    get_dict(switches, N, Sws),
    member(Sw, Sws),
    world:flags(W, Fs),
    NFs = Fs.put(Sw, true),
    world:flags(W, NFs, NW).

del_trap(N, NN) :-
    del_dict(trap, N, _, N1),
    ( del_dict(trap_inflicts, N1, _, NN) -> true ; NN = N1 ), !.
del_trap(N, N).

step_disarm(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    room(A, RId),
    world:node(W, RId, N),
    get_dict(trap, N, Dmg), !,
    stat(A, dex, Dex),
    random_between(1, 20, Roll),
    Score is Roll + Dex,
    DC is 10 + Dmg,
    ( Score >= DC ->
        del_trap(N, NN),
        world:update(W, NN, NW),
        Evts = [disarmed(Id, RId)]
    ;
        NHp is max(0, A.hp - Dmg),
        A1 = A.put(hp, NHp),
        world:update(W, A1, NW),
        Evts = [disarm_failed(Id, RId, Dmg)]
    ).
