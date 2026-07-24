:- module(prog, [add_xp/3, do_allocate/3]).

:- use_module('../core/world').
:- use_module('../core/entity').

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

valid_stat(str).
valid_stat(dex).
valid_stat(con).
valid_stat(int).
valid_stat(wis).
valid_stat(cha).
valid_stat(luk).

add_xp(ActorId, Amt, Evts) :-
    world:get_entity(ActorId, Actor),
    is_dict(Actor, plyr), !,
    get_dict(xp, Actor, CurXp),
    NXp is CurXp + Amt,
    check_level_up(Actor, NXp, NActor, LvlEvts),
    world:put_entity(NActor),
    Evts = [xp_gained(ActorId, Amt) | LvlEvts].
add_xp(_, _, []).

check_level_up(A, Xp, NA, Evts) :-
    get_dict(lvl, A, Lvl),
    get_dict(id, A, AId),
    Req is Lvl * Lvl * 100,
    Xp >= Req, !,

    NXp is Xp - Req,
    NLvl is Lvl + 1,

    ( get_dict(stat_points, A, Points) -> true ; Points = 0 ),
    NPoints is Points + 3,
    get_dict(max_hp, A, MaxHp), get_dict(max_mp, A, MaxMp),
    NMaxHp is MaxHp + 10, NMaxMp is MaxMp + 5,

    TmpA = A.put(lvl, NLvl).put(stat_points, NPoints).put(max_hp, NMaxHp).put(hp, NMaxHp).put(max_mp, NMaxMp).put(mp, NMaxMp),
    Evts = [lvl_up(AId, NLvl) | RestEvts],
    check_level_up(TmpA, NXp, NA, RestEvts).
check_level_up(A, Xp, NA, []) :-
    NA = A.put(xp, Xp).

do_allocate(Id, _StatQuery, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_allocate(Id, StatQuery, [error(invalid_stat(Id, StatQuery))]) :-
    to_atom(StatQuery, Stat),
    \+ valid_stat(Stat), !.

do_allocate(Id, _StatQuery, [error(no_stat_points(Id))]) :-
    world:get_entity(Id, Actor),
    ( get_dict(stat_points, Actor, Points) -> true ; Points = 0 ),
    Points =< 0, !.

do_allocate(Id, StatQuery, Evts) :-
    world:get_entity(Id, Actor),
    to_atom(StatQuery, Stat),
    valid_stat(Stat),
    ( get_dict(stat_points, Actor, Points) -> true ; Points = 0 ),
    Points > 0, !,
    NPoints is Points - 1,
    get_dict(Stat, Actor, CurVal),
    NVal is CurVal + 1,
    A1 = Actor.put(Stat, NVal).put(stat_points, NPoints),
    apply_stat_side_effects(Stat, A1, FinalA),
    world:put_entity(FinalA),
    Evts = [allocated(Id, Stat, NVal, NPoints)].

apply_stat_side_effects(con, A, NA) :- !,
    get_dict(max_hp, A, MaxHp), NMaxHp is MaxHp + 5,
    get_dict(hp, A, Hp), NHp is Hp + 5,
    NA = A.put(max_hp, NMaxHp).put(hp, NHp).
apply_stat_side_effects(int, A, NA) :- !,
    get_dict(max_mp, A, MaxMp), NMaxMp is MaxMp + 5,
    get_dict(mp, A, Mp), NMp is Mp + 5,
    NA = A.put(max_mp, NMaxMp).put(mp, NMp).
apply_stat_side_effects(wis, A, NA) :- !,
    get_dict(max_mp, A, MaxMp), NMaxMp is MaxMp + 3,
    get_dict(mp, A, Mp), NMp is Mp + 3,
    NA = A.put(max_mp, NMaxMp).put(mp, NMp).
apply_stat_side_effects(_, A, A).
