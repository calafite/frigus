:- module(spawn, [
    gen_mob/5, gen_grp/4, gen_town_npc/2, gen_guard_npc/2, gen_citizen_npc/2
]).

:- use_module('../core/world').
:- use_module('../config/world').
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

gen_mob(Theme, Lvl, Tier, RId, Mob) :-
    pick_mob(Theme, Base),
    world:gen_id(mob, Id),
    BaseHp is 20 + (Lvl * 10),
    BaseStr is 10 + (Lvl * 2),
    BaseDex is 10 + (Lvl * 2),
    BaseInt is 10 + (Lvl * 2),
    ( Tier == boss ->
        H1 is BaseHp * 6, S1 is BaseStr * 4, D1 is BaseDex * 4, I1 is BaseInt * 4,
        atomic_list_concat([Base, ' boss'], ' ', Name),
        Props = [dict{prop: boss, val: 1.0}]
    ; Tier == elite ->
        H1 is BaseHp * 2, S1 is BaseStr * 2, D1 is BaseDex * 2, I1 is BaseInt * 2,
        atomic_list_concat(['elite ', Base], Name),
        Props = [dict{prop: elite, val: 1.0}]
    ;
        H1 = BaseHp, S1 = BaseStr, D1 = BaseDex, I1 = BaseInt, Name = Base, Props = []
    ),
    Mob = mob{id: Id, tag: Base, name: Name, lvl: Lvl, hp: H1, max_hp: H1, str: S1, dex: D1, int: I1, room: RId, props: Props}.

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
