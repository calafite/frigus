:- module(prog, [add_xp/4]).

:- use_module(config).
:- use_module(entity).

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
    str(A, Str), NStr is Str + GS,
    dex(A, Dex), NDex is Dex + GD,
    int(A, Int), NInt is Int + GI,
    A1 = A.put(lvl, NLvl).put(str, NStr).put(dex, NDex).put(int, NInt),
    lvl_check(A1, NXp, NA, REvts).
lvl_check(A, Xp, NA, []) :-
    xp(A, Xp, NA).
