:- module(spawn, [
    gen_mob/5, gen_grp/4, gen_town_npc/2, gen_guard_npc/2, gen_citizen_npc/2
]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('../config/spawn').
:- use_module('names').
:- use_module(library(random)).
:- use_module(library(lists)).

roll_tier(T) :-
    random_between(1, 100, R),
    ( R =< 5  -> T = boss
    ; R =< 25 -> T = elite
    ; T = normal ).

pick_mob(Theme, Base) :-
    world_config:theme_data(Theme, Tags),
    random_member(Tag, Tags),
    findall(B, world_config:mob_base(Tag, B), Bs),
    ( Bs \== [] -> random_member(Base, Bs) ; Base = goblin ).

apply_elite_stat(max_hp, Mult, H, S, D, I, NH, S, D, I) :- NH is floor(H * Mult).
apply_elite_stat(str, Mult, H, S, D, I, H, NS, D, I) :- NS is floor(S * Mult).
apply_elite_stat(dex, Mult, H, S, D, I, H, S, ND, I) :- ND is floor(D * Mult).
apply_elite_stat(int, Mult, H, S, D, I, H, S, D, NI) :- NI is floor(I * Mult).
apply_elite_stat(con, Mult, H, S, D, I, NH, S, D, I) :- NH is floor(H * Mult).
apply_elite_stat(_, _, H, S, D, I, H, S, D, I).

random_elite_mod(ModName, Stat) :-
    findall(M-S, world_config:elite_mod(M, S, _), Mods),
    random_member(ModName-Stat, Mods).

gen_mob(Theme, Lvl, Tier, RId, Mob) :-
    pick_mob(Theme, BaseTag),
    world:gen_id(mob, Id),

    spawn_config:mob_stats(BaseTag, BHp, BStr, BDex, BInt),

    LevelMod is 1.0 + (Lvl * 0.2),
    Hp1 is floor(BHp * LevelMod),
    Str1 is max(1, floor(BStr * LevelMod)),
    Dex1 is max(1, floor(BDex * LevelMod)),
    Int1 is max(1, floor(BInt * LevelMod)),

    ( Tier == boss ->
        H2 is Hp1 * 4, S2 is Str1 * 2, D2 is Dex1 * 2, I2 is Int1 * 2,
        random_elite_mod(EMod, StatBoost),
        apply_elite_stat(StatBoost, 2.0, H2, S2, D2, I2, FinalH, FinalS, FinalD, FinalI),
        atomic_list_concat([EMod, BaseTag, boss], '_', RawName),
        Props = [dict{prop: boss, val: 1.0}, dict{prop: elite_mod, val: EMod}]
    ; Tier == elite ->
        H2 is floor(Hp1 * 1.5), S2 is floor(Str1 * 1.5), D2 is floor(Dex1 * 1.5), I2 is floor(Int1 * 1.5),
        random_elite_mod(EMod, StatBoost),
        apply_elite_stat(StatBoost, 1.5, H2, S2, D2, I2, FinalH, FinalS, FinalD, FinalI),
        atomic_list_concat([EMod, BaseTag], '_', RawName),
        Props = [dict{prop: elite, val: 1.0}, dict{prop: elite_mod, val: EMod}]
    ;
        FinalH = Hp1, FinalS = Str1, FinalD = Dex1, FinalI = Int1,
        RawName = BaseTag, Props = []
    ),

    Mob = mob{id: Id, tag: BaseTag, name: RawName, lvl: Lvl, hp: FinalH, max_hp: FinalH, str: FinalS, dex: FinalD, int: FinalI, room: RId, props: Props}.

gen_grp(Theme, Lvl, RId, Mobs) :-
    random_between(0, 2, Count),
    findall(M, (between(1, Count, _), roll_tier(T), gen_mob(Theme, Lvl, T, RId, M)), Mobs).

gen_guard_npc(RoomId, Npc) :-
    world:gen_id(guard, NpcId),
    random_between(1, 100, Roll),
    Seed is Roll * 7919,
    names:gen_npc_name(Seed, RawName, _),
    atomic_list_concat(['Guard ', RawName], Name),
    Npc = mob{id: NpcId, tag: guard, name: Name, lvl: 5, hp: 100, max_hp: 100, str: 18, dex: 15, int: 10, room: RoomId, fac: guard, props: [protector], equip: dict{wpn: iron_sword, shield: wooden_shield, body: chainmail}}.

gen_citizen_npc(RoomId, Npc) :-
    world:gen_id(peasant, NpcId),
    random_between(1, 100, Roll),
    Seed is Roll * 3571,
    names:gen_npc_name(Seed, RawName, _),
    Npc = mob{id: NpcId, tag: peasant, name: RawName, lvl: 1, hp: 30, max_hp: 30, str: 10, dex: 10, int: 10, room: RoomId, fac: citizen, props: [], equip: dict{wpn: fists, shield: none, body: tunic}}.

gen_town_npc(RoomId, Npc) :-
    random_between(1, 100, Roll),
    ( Roll =< 60 ->
        gen_guard_npc(RoomId, Npc)
    ;
        gen_citizen_npc(RoomId, Npc)
    ).
