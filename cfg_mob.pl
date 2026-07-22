:- module(cfg_mob, [
    mob_xp/2, loot_table/5, aggression/2, habitat/2
]).

mob_xp(rat, 10).
mob_xp(bat, 12).
mob_xp(snake, 15).
mob_xp(giant_spider, 35).
mob_xp(wolf, 40).
mob_xp(boar, 45).
mob_xp(bear, 80).
mob_xp(shadow_panther, 120).
mob_xp(basilisk, 180).
mob_xp(griffin, 250).
mob_xp(dragon, 2000).

mob_xp(goblin, 25).
mob_xp(orc, 60).
mob_xp(bandit, 50).
mob_xp(thief, 45).
mob_xp(cultist, 70).
mob_xp(dark_knight, 200).
mob_xp(necromancer, 300).

mob_xp(skeleton, 30).
mob_xp(zombie, 35).
mob_xp(ghoul, 50).
mob_xp(wraith, 150).
mob_xp(vampire, 400).
mob_xp(lich, 1500).

mob_xp(imp, 60).
mob_xp(hellhound, 90).
mob_xp(succubus, 180).
mob_xp(demon, 500).
mob_xp(balor, 2500).

mob_xp(slime, 20).
mob_xp(fire_sprite, 40).
mob_xp(elemental, 100).
mob_xp(golem, 250).

mob_xp(citizen, 10).
mob_xp(peasant, 10).
mob_xp(merchant, 50).
mob_xp(guard, 100).
mob_xp(paladin, 250).
mob_xp(priest, 80).
mob_xp(_, 50).

loot_table(rat, gold, 0.3, 1, 3).
loot_table(bat, gold, 0.2, 1, 2).
loot_table(snake, snake_skin, 0.5, 1, 1).
loot_table(giant_spider, spider_venom, 0.6, 1, 2).
loot_table(wolf, wolf_pelt, 0.8, 1, 1).
loot_table(boar, pork, 1.0, 1, 2).
loot_table(bear, bear_pelt, 0.9, 1, 1).
loot_table(shadow_panther, shadow_essence, 0.2, 1, 1).
loot_table(basilisk, basilisk_scale, 0.7, 1, 3).
loot_table(griffin, griffin_feather, 0.8, 1, 3).
loot_table(dragon, dragon_scale, 1.0, 2, 5).
loot_table(dragon, gold, 1.0, 500, 2000).

loot_table(goblin, gold, 0.8, 3, 12).
loot_table(goblin, bronze_dagger, 0.1, 1, 1).
loot_table(orc, gold, 0.9, 8, 25).
loot_table(orc, iron_mace, 0.15, 1, 1).
loot_table(bandit, gold, 1.0, 10, 40).
loot_table(bandit, leather_armor, 0.1, 1, 1).
loot_table(cultist, gold, 0.8, 15, 50).
loot_table(cultist, mana_potion, 0.3, 1, 2).

loot_table(skeleton, bone_armor, 0.05, 1, 1).
loot_table(zombie, gold, 0.2, 1, 5).
loot_table(wraith, shadow_essence, 0.5, 1, 2).
loot_table(vampire, gold, 1.0, 100, 300).

loot_table(imp, fire_lily, 0.2, 1, 1).
loot_table(demon, gold, 1.0, 200, 600).
loot_table(slime, health_potion, 0.2, 1, 1).
loot_table(golem, iron_ore, 0.8, 2, 6).

loot_table(merchant, gold, 1.0, 100, 500).
loot_table(guard, iron_sword, 0.5, 1, 1).

aggression(rat, neutral).
aggression(bat, neutral).
aggression(snake, aggressive).
aggression(giant_spider, aggressive).
aggression(wolf, aggressive).
aggression(boar, neutral).
aggression(bear, aggressive).
aggression(shadow_panther, aggressive).
aggression(basilisk, aggressive).
aggression(griffin, neutral).
aggression(dragon, aggressive).

aggression(goblin, aggressive).
aggression(orc, aggressive).
aggression(bandit, aggressive).
aggression(thief, neutral).
aggression(cultist, aggressive).

aggression(skeleton, aggressive).
aggression(zombie, aggressive).
aggression(wraith, aggressive).
aggression(vampire, aggressive).
aggression(lich, aggressive).

aggression(imp, aggressive).
aggression(demon, aggressive).
aggression(slime, aggressive).
aggression(golem, neutral).

aggression(citizen, neutral).
aggression(peasant, neutral).
aggression(merchant, neutral).
aggression(guard, neutral).
aggression(_, aggressive).

habitat(rat, sewer).
habitat(giant_spider, cavern).
habitat(wolf, forest).
habitat(bear, forest).
habitat(shadow_panther, cavern).
habitat(griffin, sky).
habitat(dragon, volcano).
habitat(goblin, cavern).
habitat(orc, plains).
habitat(bandit, forest).
habitat(skeleton, crypt).
habitat(zombie, crypt).
habitat(wraith, tomb).
habitat(vampire, keep).
habitat(imp, inferno).
habitat(demon, abyss).
habitat(slime, sewer).
habitat(citizen, city).
habitat(merchant, market).
habitat(guard, city).
habitat(_, wilderness).
