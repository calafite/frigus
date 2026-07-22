:- module(quest_gen, [
    db_generated_quest/4,
    step_ask_quest/5,
    gen_quest/3
]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(quest).

:- dynamic db_generated_quest/4.

npc_theme(peasant, farming).
npc_theme(farmer, farming).
npc_theme(miner, mining).
npc_theme(guard, military).
npc_theme(merchant, commerce).
npc_theme(_, general).

gen_pool(farming, kill(boar, 5), [xp(200), gold(80)]).
gen_pool(farming, fetch(wheat, 10), [xp(150), gold(50)]).
gen_pool(mining, fetch(iron_ore, 8), [xp(300), gold(150)]).
gen_pool(mining, kill(rock_worm, 3), [xp(400), gold(200)]).
gen_pool(military, kill(bandit, 8), [xp(500), gold(250)]).
gen_pool(military, kill(thief, 5), [xp(400), gold(150)]).
gen_pool(commerce, fetch(gold_ingot, 2), [xp(600), gold(400)]).
gen_pool(commerce, fetch(silver_ingot, 3), [xp(450), gold(300)]).
gen_pool(general, kill(rat, 10), [xp(100), gold(30)]).
gen_pool(general, fetch(berries, 15), [xp(120), gold(40)]).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

gen_quest(NpcTag, QId, db) :-
    id_gen(q_gen, QId),
    ( npc_theme(NpcTag, Theme) -> true ; Theme = general ),
    findall(O-R, gen_pool(Theme, O, R), Pool),
    random_member(Obj-Rews, Pool),
    assertz(db_generated_quest(NpcTag, QId, [Obj], Rews)).

step_ask_quest(W, Id, NpcId, NW, Evts) :-
    world:entity(W, Id, A),
    world:entity(W, NpcId, Npc),
    quests(A, Qs),
    ( get_dict(active_gen_quest, Npc, QId) ->
        ( get_dict(QId, Qs, _) ->
            Evts = [already_active(QId)], NW = W
        ;
            quest:step_accept(W, Id, QId, NW, Evts)
        )
    ;
        gen_quest(Npc.tag, QId, db),
        Npc1 = Npc.put(active_gen_quest, QId),
        world:update(W, Npc1, W1),
        quest:step_accept(W1, Id, QId, NW, Evts)
    ).
