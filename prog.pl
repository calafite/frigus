:- module(prog, [add_xp/4, step_train/5]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

add_xp(A, Amt, NA, Evts) :-
    xp(A, Cur),
    NXp is Cur + Amt,
    lvl_check(A, NXp, NA, Evts).

lvl_check(A, Xp, NA, [lvl_up(A.id, NLvl) | REvts]) :-
    lvl(A, Lvl),
    Req is Lvl * Lvl * 100,
    Xp >= Req, !,
    NXp is Xp - Req,
    NLvl is Lvl + 1,
    class(A, C),
    config:growth(C, str, GS), config:growth(C, dex, GD), config:growth(C, int, GI),
    get_ceil(A, str, CS), str(A, Str), NStr is min(CS, Str + GS),
    get_ceil(A, dex, CD), dex(A, Dex), NDex is min(CD, Dex + GD),
    get_ceil(A, int, CI), int(A, Int), NInt is min(CI, Int + GI),
    A1 = A.put(lvl, NLvl).put(str, NStr).put(dex, NDex).put(int, NInt),
    lvl_check(A1, NXp, NA, REvts).
lvl_check(A, Xp, NA, []) :-
    xp(A, Xp, NA).

step_train(W, Id, Stat, NW, Evts) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    stat(A, Stat, Val),
    Cost is Val * 20,
    xp(A, Xp), Xp >= Cost,
    NXp is Xp - Cost,
    get_ceil(A, Stat, Ceil),
    ( Val < Ceil ->
        NVal is Val + 1,
        A1 = A.put(xp, NXp).put(Stat, NVal),
        Evts = [trained(Id, Stat, NVal)],
        world:update(W, A1, NW)
    ;
        random_between(1, 100, Roll),
        ( Roll <= 5 ->
            NCeil is Ceil + 1,
            NVal is Val + 1,
            ceils(A, Ceils),
            NCeils = Ceils.put(Stat, NCeil),
            A1 = A.put(xp, NXp).put(Stat, NVal).put(ceils, NCeils),
            Evts = [breakthrough(Id, Stat, NCeil, NVal)],
            world:update(W, A1, NW)
        ;
            A1 = A.put(xp, NXp),
            Evts = [train_failed(Id, Stat)],
            world:update(W, A1, NW)
        )
    ).
