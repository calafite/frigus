:- module(cfg_mob, [
    mob_xp/2,
    loot_table/5,
    aggression/2,
    habitat/2
]).

mob_xp(goblin, 120).
mob_xp(wolf, 150).
mob_xp(basilisk, 400).
mob_xp(phoenix, 600).
mob_xp(shadow_panther, 300).
mob_xp(bear, 250).
mob_xp(rat, 30).
mob_xp(giant_spider, 140).
mob_xp(griffin, 350).
mob_xp(boar, 80).
mob_xp(deer, 45).
mob_xp(chicken, 10).
mob_xp(sheep, 20).
mob_xp(cow, 30).
mob_xp(horse, 60).
mob_xp(cat, 10).
mob_xp(fox, 35).
mob_xp(snake, 50).
mob_xp(goat, 30).
mob_xp(_, 100).

loot_table(goblin, gold, 1.0, 5, 20).
loot_table(goblin, potion, 0.4, 1, 2).
loot_table(goblin, sword, 0.05, 1, 1).
loot_table(orc, gold, 1.0, 15, 45).
loot_table(orc, shield, 0.1, 1, 1).
loot_table(slime, potion, 0.25, 1, 1).
loot_table(bear, gold, 1.0, 10, 30).
loot_table(bear, bear_pelt, 1.0, 1, 1).
loot_table(rat, gold, 0.3, 1, 5).
loot_table(giant_spider, spider_venom, 0.8, 1, 2).
loot_table(griffin, gold, 1.0, 30, 80).
loot_table(griffin, griffin_feather, 1.0, 1, 3).
loot_table(boar, gold, 0.5, 1, 5).
loot_table(boar, pork, 1.0, 1, 2).
loot_table(boar, leather, 0.7, 1, 1).
loot_table(deer, venison, 1.0, 1, 2).
loot_table(deer, leather, 1.0, 1, 1).
loot_table(chicken, chicken_meat, 1.0, 1, 1).
loot_table(chicken, feather, 1.0, 1, 3).
loot_table(sheep, mutton, 1.0, 1, 1).
loot_table(sheep, wool, 1.0, 1, 2).
loot_table(cow, beef, 1.0, 2, 4).
loot_table(cow, leather, 1.0, 1, 2).
loot_table(horse, leather, 1.0, 1, 2).
loot_table(fox, gold, 0.5, 5, 15).
loot_table(snake, snake_skin, 1.0, 1, 1).
loot_table(goat, mutton, 1.0, 1, 2).

aggression(dog, neutral).
aggression(wolf, aggressive).
aggression(basilisk, aggressive).
aggression(phoenix, neutral).
aggression(shadow_panther, aggressive).
aggression(bear, aggressive).
aggression(rat, neutral).
aggression(giant_spider, aggressive).
aggression(griffin, neutral).
aggression(boar, aggressive).
aggression(deer, neutral).
aggression(chicken, neutral).
aggression(sheep, neutral).
aggression(cow, neutral).
aggression(horse, neutral).
aggression(cat, neutral).
aggression(fox, neutral).
aggression(snake, aggressive).
aggression(goat, neutral).
aggression(_, aggressive).

habitat(dog, settlement).
habitat(dog, forest).
habitat(wolf, forest).
habitat(basilisk, cave).
habitat(basilisk, swamp).
habitat(phoenix, volcano).
habitat(shadow_panther, cave).
habitat(bear, forest).
habitat(bear, cave).
habitat(rat, swamp).
habitat(rat, cave).
habitat(giant_spider, forest).
habitat(giant_spider, cave).
habitat(griffin, peaks).
habitat(griffin, forest).
habitat(boar, forest).
habitat(deer, forest).
habitat(chicken, settlement).
habitat(sheep, settlement).
habitat(cow, settlement).
habitat(horse, settlement).
habitat(horse, forest).
habitat(cat, settlement).
habitat(fox, forest).
habitat(snake, forest).
habitat(snake, swamp).
habitat(goat, peaks).
habitat(_, _).
