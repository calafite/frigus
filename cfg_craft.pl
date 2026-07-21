:- module(cfg_craft, [recipe/5, station/2]).

recipe(iron_ingot, 1, smithing, 1, [stack{tag: iron_ore, qty: 2}, stack{tag: coal, qty: 1}]).
recipe(steel_ingot, 1, smithing, 5, [stack{tag: iron_ore, qty: 1}, stack{tag: coal, qty: 2}]).
recipe(silver_ingot, 1, smithing, 8, [stack{tag: silver_ore, qty: 2}, stack{tag: coal, qty: 1}]).
recipe(gold_ingot, 1, smithing, 12, [stack{tag: gold_ore, qty: 2}, stack{tag: coal, qty: 2}]).
recipe(electrum_ingot, 1, smithing, 10, [stack{tag: silver_ingot, qty: 1}, stack{tag: gold_ingot, qty: 1}, stack{tag: coal, qty: 1}]).

recipe(wooden_club, 1, smithing, 1, [stack{tag: timber, qty: 2}]).
recipe(bronze_dagger, 1, smithing, 1, [stack{tag: copper_ore, qty: 1}, stack{tag: timber, qty: 1}]).
recipe(bronze_sword, 1, smithing, 2, [stack{tag: copper_ore, qty: 3}, stack{tag: timber, qty: 1}]).
recipe(dagger, 1, smithing, 2, [stack{tag: iron_ingot, qty: 1}, stack{tag: timber, qty: 1}]).
recipe(sword, 1, smithing, 4, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 1}]).
recipe(iron_mace, 1, smithing, 3, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 1}]).
recipe(iron_spear, 1, smithing, 4, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 2}]).
recipe(steel_claymore, 1, smithing, 10, [stack{tag: steel_ingot, qty: 3}, stack{tag: timber, qty: 2}]).
recipe(steel_halberd, 1, smithing, 11, [stack{tag: steel_ingot, qty: 3}, stack{tag: timber, qty: 3}]).
recipe(composite_bow, 1, smithing, 5, [stack{tag: timber, qty: 3}, stack{tag: wool, qty: 2}]).

recipe(excalibur, 1, smithing, 25, [stack{tag: steel_ingot, qty: 5}, stack{tag: gold_ingot, qty: 2}, stack{tag: sunstone, qty: 2}]).
recipe(shadowfang, 1, smithing, 22, [stack{tag: dagger, qty: 1}, stack{tag: shadow_essence, qty: 3}, stack{tag: spider_venom, qty: 2}]).
recipe(gungnir, 1, smithing, 24, [stack{tag: silver_ingot, qty: 4}, stack{tag: griffin_feather, qty: 4}, stack{tag: timber, qty: 2}]).

recipe(leather_vest, 1, smithing, 1, [stack{tag: leather, qty: 2}]).
recipe(leather_armor, 1, smithing, 4, [stack{tag: leather, qty: 4}]).
recipe(plate_mail, 1, smithing, 15, [stack{tag: steel_ingot, qty: 5}, stack{tag: leather, qty: 2}]).
recipe(shield, 1, smithing, 3, [stack{tag: timber, qty: 3}, stack{tag: iron_ingot, qty: 1}]).
recipe(tower_shield, 1, smithing, 12, [stack{tag: iron_ingot, qty: 4}, stack{tag: timber, qty: 1}]).
recipe(robe, 1, smithing, 2, [stack{tag: wool, qty: 3}, stack{tag: blue_lotus, qty: 1}]).

recipe(potion, 1, alchemy, 1, [stack{tag: blue_lotus, qty: 1}]).
recipe(antidote, 1, alchemy, 3, [stack{tag: blue_lotus, qty: 1}, stack{tag: spider_venom, qty: 1}]).
recipe(haste_potion, 1, alchemy, 7, [stack{tag: griffin_feather, qty: 2}, stack{tag: potion, qty: 1}]).
recipe(str_potion, 1, alchemy, 5, [stack{tag: fire_lily, qty: 1}, stack{tag: sulfur, qty: 1}]).
recipe(elixir_of_life, 1, alchemy, 20, [stack{tag: potion, qty: 1}, stack{tag: sunstone, qty: 1}, stack{tag: fire_lily, qty: 2}]).
recipe(mana_potion, 1, alchemy, 5, [stack{tag: blue_lotus, qty: 2}, stack{tag: silver_ore, qty: 1}]).

station(smithing, forge).
station(alchemy, laboratory).
