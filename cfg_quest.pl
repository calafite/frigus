:- module(cfg_quest, [quest_data/3]).

quest_data(q_rats, [kill(rat, 5), fetch(rat_tail, 3)], [xp(150), gold(50)]).
quest_data(q_spiders, [kill(giant_spider, 8), fetch(spider_silk, 5)], [xp(300), gold(100), item(potion, 2)]).
quest_data(q_goblins, [kill(goblin, 12)], [xp(400), item(bronze_sword, 1)]).
quest_data(q_lost_heirloom, [fetch(silver_ring, 1)], [gold(200), xp(250)]).
quest_data(q_bandits, [kill(bandit, 10), talk(guard_captain)], [xp(500), gold(300)]).
quest_data(q_wolves, [kill(wolf, 8), fetch(wolf_pelt, 5)], [xp(350), gold(150)]).
quest_data(q_orc_camp, [kill(orc, 15)], [xp(800), item(iron_ingot, 5)]).
quest_data(q_undead, [kill(skeleton, 10), kill(zombie, 10)], [xp(1000), item(holy_water, 3)]).
quest_data(q_necromancer, [kill(necromancer, 1), fetch(dark_tome, 1)], [xp(2000), gold(1000)]).
quest_data(q_dragon, [kill(dragon, 1), fetch(dragon_scale, 3)], [xp(5000), item(excalibur, 1)]).
quest_data(q_herb_fetch, [fetch(blue_lotus, 10), fetch(fire_lily, 5)], [xp(500), item(elixir_of_life, 2)]).
quest_data(q_bear_hunt, [kill(bear, 5), fetch(bear_pelt, 3)], [xp(450), gold(200)]).
quest_data(q_cultists, [kill(cultist, 12), talk(priest)], [xp(1200), item(amulet, 1)]).
quest_data(q_demons, [kill(imp, 15), kill(hellhound, 5)], [xp(1500), gold(500)]).
quest_data(q_vampire, [kill(vampire, 2), fetch(vampire_fang, 2)], [xp(1800), item(silver_sword, 1)]).
quest_data(q_slime_cores, [kill(slime, 20), fetch(slime_core, 10)], [xp(600), item(mana_potion, 5)]).
quest_data(q_golem, [kill(golem, 3), fetch(golem_core, 1)], [xp(1500), item(steel_ingot, 3)]).
quest_data(q_report, [talk(commander), talk(king)], [xp(1000), gold(500)]).
quest_data(q_shadows, [kill(shadow_panther, 5), kill(wraith, 5)], [xp(1400), item(shadow_essence, 2)]).
quest_data(q_angels, [kill(angel, 3), fetch(angel_feather, 3)], [xp(2500), item(demonic_blade, 1)]).
