:- module(cfg_gather, [
    node_yield/4,
    skin_yield/3
]).

node_yield(iron_vein, iron_ore, pickaxe, mining).
node_yield(gold_vein, gold_ore, pickaxe, mining).
node_yield(silver_vein, silver_ore, pickaxe, mining).
node_yield(copper_vein, copper_ore, pickaxe, mining).
node_yield(coal_vein, coal, pickaxe, mining).
node_yield(oak_tree, timber, axe, logging).
node_yield(pine_tree, timber, axe, logging).
node_yield(yew_tree, timber, axe, logging).
node_yield(herb_patch, blue_lotus, none, foraging).
node_yield(fire_patch, fire_lily, none, foraging).
node_yield(berry_bush, berries, none, foraging).
node_yield(mushroom_patch, cave_mushroom, none, foraging).

skin_yield(wolf, wolf_pelt, 1).
skin_yield(bear, bear_pelt, 1).
skin_yield(boar, leather, 2).
skin_yield(deer, leather, 1).
skin_yield(dragon, dragon_scale, 3).
skin_yield(giant_spider, spider_silk, 2).
skin_yield(shadow_panther, shadow_pelt, 1).
skin_yield(basilisk, basilisk_scale, 2).
skin_yield(snake, snake_skin, 1).
skin_yield(cow, leather, 2).
skin_yield(sheep, wool, 2).
