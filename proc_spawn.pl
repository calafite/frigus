:- module(proc_spawn, [gen_mob/5, gen_grp/4]).

:- use_module(library(random)).
:- use_module(cfg_proc).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

roll_elite(T) :-
    random_between(1, 100, R),
    ( R =< 5  -> T = boss
    ; R =< 25 -> T = elite
    ; T = normal ).

pick_mob(Theme, Base) :-
    cfg_proc:theme_data(Theme, Tags),
    random_member(Tag, Tags),
    findall(B, mob_base(Tag, B), Bs),
    random_member(Base, Bs).

gen_mob(Theme, Lvl, Tier, RId, Mob) :-
    pick_mob(Theme, Base),
    id_gen(mob, Id),
    BaseHp is 20 + (Lvl * 10),
    BaseStr is 10 + (Lvl * 2),
    BaseDex is 10 + (Lvl * 2),
    BaseInt is 10 + (Lvl * 2),
    ( Tier == elite ->
        findall(M, elite_mod(M, _, _), Mods), random_member(Mod, Mods),
        atomic_list_concat([Mod, Base], ' ', Name),
        apply_mod(Mod, BaseHp, BaseStr, BaseDex, BaseInt, [], Hp, Str, Dex, Int, Props)
    ; Tier == boss ->
        findall(M, elite_mod(M, _, _), Mods), random_permutation(Mods, [M1, M2|_]),
        atomic_list_concat([M1, M2, Base, boss], ' ', Name),
        apply_mod(M1, BaseHp, BaseStr, BaseDex, BaseInt, [], H1, S1, D1, I1, P1),
        apply_mod(M2, H1, S1, D1, I1, P1, Hp, Str, Dex, Int, Props)
    ;
        Name = Base, Hp = BaseHp, Str = BaseStr, Dex = BaseDex, Int = BaseInt, Props = []
    ),
    Mob = mob{id: Id, tag: Base, name: Name, lvl: Lvl, hp: Hp, max_hp: Hp, str: Str, dex: Dex, int: Int, room: RId, props: Props}.

apply_mod(Mod, H, S, D, I, P, NH, NS, ND, NI, NP) :-
    elite_mod(Mod, Stat, Mult),
    ( Stat == max_hp -> NH is floor(H * Mult), NS = S, ND = D, NI = I, NP = P
    ; Stat == str    -> NS is floor(S * Mult), NH = H, ND = D, NI = I, NP = P
    ; Stat == dex    -> ND is floor(D * Mult), NH = H, NS = S, NI = I, NP = P
    ; Stat == int    -> NI is floor(I * Mult), NH = H, NS = S, ND = D, NP = P
    ; NH = H, NS = S, ND = D, NI = I, NP = [prop(Stat, Mult)|P]
    ).

gen_grp(Theme, Lvl, RId, Mobs) :-
    random_between(0, 3, Count),
    findall(M, (between(1, Count, _), roll_elite(T), gen_mob(Theme, Lvl, T, RId, M)), Mobs).
