:- module(combat, [step_kill/5, step_cast/6, valid_target/3]).

:- use_module(library(lists)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).
:- use_module(drop).

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

calc_dmg(A, Tag, Final) :-
    config:dmg(Tag, Base),
    config:scale(Tag, Stat, Mult),
    stat(A, Stat, Val),
    Final is Base + floor(Val * Mult).

step_kill(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    crime_check(A, T, MidA),
    wpn(MidA, Wpn),
    calc_dmg(MidA, Wpn, Dmg),
    apply_dmg(W, MidA, T, Dmg, NW, Evts, hit(AId, TId, Dmg)).

step_cast(W, AId, Sp, TId, NW, Evts) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    config:req(Sp, ReqStat, ReqVal),
    stat(A, ReqStat, Val),
    Val >= ReqVal,
    crime_check(A, T, MidA),
    cost(Sp, Cost),
    mp(MidA, Mp),
    Mp >= Cost,
    NMp is Mp - Cost,
    mp(MidA, NMp, CastA),
    calc_dmg(CastA, Sp, Dmg),
    apply_dmg(W, CastA, T, Dmg, NW, Evts, cast(AId, Sp, TId, Dmg)).

apply_dmg(W, A, T, Dmg, NW, [HitEvt, dead(TId) | REvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, NTHp =< 0, !,
    hp(T, 0, NT), TId = NT.id, reward(W, A, NT, NW, REvts).
apply_dmg(W, A, T, Dmg, NW, [HitEvt], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, hp(T, NTHp, NT),
    world:update(W, A, TW), world:update(TW, NT, NW).

reward(W, A, mob{id: MId, tag: Tag} = M, NW, [xp(AId, Xp) | Evts]) :-
    config:mob_xp(Tag, Xp),
    AId = A.id,
    prog:add_xp(A, Xp, NA, ProgEvts),
    world:remove(W, MId, W1),
    world:update(W1, NA, W2),
    drop:gen_drops(W2, M, NW, DropEvts),
    append(ProgEvts, DropEvts, Evts).
reward(W, A, plyr{id: PId} = NT, NW, []) :-
    world:update(W, A, TW), world:update(TW, NT, NW).
