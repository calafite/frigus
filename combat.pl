:- module(combat, [step_kill/5, step_cast/6]).

:- use_module(config).
:- use_module(entity).
:- use_module(world).

is_crime(FA, FB) :- \+ config:enemy(FA, FB), FA \== criminal.

crime_check(A, T, NA) :-
    fac(A, FA), fac(T, FT),
    is_crime(FA, FT), !,
    fac(A, criminal, NA).
crime_check(A, _, A).

valid_target(W, A, T) :-
    alive(A), alive(T),
    room(A, RId), room(T, RId),
    world:node(W, RId, N),
    \+ member(safe, N.props).

step_kill(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    crime_check(A, T, MidA),
    wpn(MidA, Wpn),
    dmg(Wpn, Dmg),
    apply_dmg(W, MidA, T, Dmg, NW, Evts, hit(AId, TId, Dmg)).

step_cast(W, AId, Sp, TId, NW, Evts) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    crime_check(A, T, MidA),
    cost(Sp, Cost),
    mp(MidA, Mp),
    Mp >= Cost,
    NMp is Mp - Cost,
    mp(MidA, NMp, CastA),
    dmg(Sp, Dmg),
    apply_dmg(W, CastA, T, Dmg, NW, Evts, cast(AId, Sp, TId, Dmg)).

apply_dmg(W, A, T, Dmg, NW, [HitEvt, dead(TId) | REvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, NTHp =< 0, !,
    hp(T, 0, NT), TId = NT.id, reward(W, A, NT, NW, REvts).
apply_dmg(W, A, T, Dmg, NW, [HitEvt], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, hp(T, NTHp, NT),
    world:update(W, A, TW), world:update(TW, NT, NW).

reward(W, A, mob{id: MId}, NW, [lvl_up(A.id, NLvl)]) :-
    lvl(A, Lvl), NLvl is Lvl + 1, lvl(A, NLvl, NA),
    world:remove(W, MId, TW), world:update(TW, NA, NW).
reward(W, A, plyr{id: PId} = NT, NW, []) :-
    world:update(W, A, TW), world:update(TW, NT, NW).
