:- module(combat, [step_kill/5, step_cast/6]).

:- use_module(config).
:- use_module(entity).

hostile_at(A, B) :-
    alive(A),
    alive(B),
    room(A, RId),
    room(B, RId),
    hostile(A, B).

step_kill(S, AId, TId, NS, Evts) :-
    has(S, AId, A),
    has(S, TId, T),
    hostile_at(A, T),
    wpn(A, Wpn),
    dmg(Wpn, Dmg),
    apply_dmg(S, A, T, Dmg, NS, Evts, hit(AId, TId, Dmg)).

step_cast(S, AId, Sp, TId, NS, Evts) :-
    has(S, AId, A),
    has(S, TId, T),
    hostile_at(A, T),
    cost(Sp, Cost),
    mp(A, Mp),
    Mp >= Cost,
    NMp is Mp - Cost,
    mp(A, NMp, MidA),
    dmg(Sp, Dmg),
    apply_dmg(S, MidA, T, Dmg, NS, Evts, cast(AId, Sp, TId, Dmg)).

apply_dmg(S, A, T, Dmg, NS, [HitEvt, dead(TId) | REvts], HitEvt) :-
    hp(T, THp),
    NTHp is THp - Dmg,
    NTHp =< 0, !,
    hp(T, 0, NT),
    TId = NT.id,
    reward(S, A, NT, NS, REvts).

apply_dmg(S, A, T, Dmg, NS, [HitEvt], HitEvt) :-
    hp(T, THp),
    NTHp is THp - Dmg,
    hp(T, NTHp, NT),
    put(S, A.id, A, TS),
    put(TS, T.id, NT, NS).

reward(S, A, mob{id: MId}, NS, [lvl_up(A.id, NLvl)]) :-
    lvl(A, Lvl),
    NLvl is Lvl + 1,
    lvl(A, NLvl, NA),
    del(S, MId, TS),
    put(TS, A.id, NA, NS).

reward(S, A, plyr{id: PId} = NT, NS, []) :-
    put(S, A.id, A, TS),
    put(TS, PId, NT, NS).
