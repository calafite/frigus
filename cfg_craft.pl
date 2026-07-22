:- module(cfg_craft, [recipe/5, station/2]).

recipe(iron_ingot, 1, smithing, 1, [stack{tag: iron_ore, qty: 2}, stack{tag: coal, qty: 1}]).
recipe(steel_ingot, 1, smithing, 5, [stack{tag: iron_ore, qty: 1}, stack{tag: coal, qty: 2}]).
recipe(silver_ingot, 1, smithing, 8, [stack{tag: silver_ore, qty: 2}, stack{tag: coal, qty: 1}]).
recipe(gold_ingot, 1, smithing, 12, [stack{tag: gold_ore, qty: 2}, stack{tag: coal, qty: 2}]).
recipe(electrum_ingot, 1, smithing, 15, [stack{tag: silver_ingot, qty: 1}, stack{tag: gold_ingot, qty: 1}, stack{tag: coal, qty: 1}]).

recipe(wooden_club, 1, woodworking, 1, [stack{tag: timber, qty: 2}]).
recipe(shortbow, 1, woodworking, 3, [stack{tag: timber, qty: 3}, stack{tag: spider_silk, qty: 1}]).
recipe(longbow, 1, woodworking, 8, [stack{tag: timber, qty: 4}, stack{tag: spider_silk, qty: 2}]).
recipe(composite_bow, 1, woodworking, 15, [stack{tag: timber, qty: 3}, stack{tag: bone, qty: 2}, stack{tag: spider_silk, qty: 2}]).
recipe(magic_wand, 1, woodworking, 10, [stack{tag: timber, qty: 1}, stack{tag: shadow_essence, qty: 1}]).
recipe(staff, 1, woodworking, 5, [stack{tag: timber, qty: 3}]).

recipe(bronze_dagger, 1, smithing, 1, [stack{tag: copper_ore, qty: 1}, stack{tag: timber, qty: 1}]).
recipe(bronze_sword, 1, smithing, 2, [stack{tag: copper_ore, qty: 3}, stack{tag: timber, qty: 1}]).
recipe(dagger, 1, smithing, 3, [stack{tag: iron_ingot, qty: 1}, stack{tag: timber, qty: 1}]).
recipe(sword, 1, smithing, 5, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 1}]).
recipe(iron_mace, 1, smithing, 4, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 1}]).
recipe(iron_spear, 1, smithing, 6, [stack{tag: iron_ingot, qty: 2}, stack{tag: timber, qty: 2}]).
recipe(steel_claymore, 1, smithing, 12, [stack{tag: steel_ingot, qty: 4}, stack{tag: timber, qty: 2}]).
recipe(steel_halberd, 1, smithing, 14, [stack{tag: steel_ingot, qty: 3}, stack{tag: timber, qty: 3}]).

recipe(excalibur, 1, smithing, 50, [stack{tag: steel_ingot, qty: 5}, stack{tag: gold_ingot, qty: 2}, stack{tag: sunstone, qty: 2}]).
recipe(shadowfang, 1, smithing, 45, [stack{tag: dagger, qty: 1}, stack{tag: shadow_essence, qty: 3}, stack{tag: spider_venom, qty: 2}]).
recipe(gungnir, 1, smithing, 48, [stack{tag: silver_ingot, qty: 4}, stack{tag: griffin_feather, qty: 4}, stack{tag: timber, qty: 2}]).

recipe(leather_vest, 1, tailoring, 1, [stack{tag: leather, qty: 2}]).
recipe(leather_armor, 1, tailoring, 5, [stack{tag: leather, qty: 4}]).
recipe(studded_leather, 1, tailoring, 10, [stack{tag: leather, qty: 4}, stack{tag: iron_ingot, qty: 1}]).
recipe(spider_silk_robe, 1, tailoring, 20, [stack{tag: spider_silk, qty: 5}, stack{tag: shadow_essence, qty: 1}]).
recipe(shadow_cloak, 1, tailoring, 35, [stack{tag: shadow_pelt, qty: 3}, stack{tag: shadow_essence, qty: 2}]).

recipe(chainmail, 1, smithing, 15, [stack{tag: iron_ingot, qty: 6}]).
recipe(scale_mail, 1, smithing, 20, [stack{tag: steel_ingot, qty: 5}, stack{tag: leather, qty: 2}]).
recipe(half_plate, 1, smithing, 25, [stack{tag: steel_ingot, qty: 6}, stack{tag: leather, qty: 3}]).
recipe(plate_mail, 1, smithing, 35, [stack{tag: steel_ingot, qty: 8}, stack{tag: leather, qty: 2}]).
recipe(dragon_scale_armor, 1, smithing, 60, [stack{tag: dragon_scale, qty: 5}, stack{tag: gold_ingot, qty: 2}, stack{tag: leather, qty: 3}]).

recipe(wooden_shield, 1, woodworking, 2, [stack{tag: timber, qty: 3}]).
recipe(iron_shield, 1, smithing, 8, [stack{tag: iron_ingot, qty: 3}, stack{tag: timber, qty: 1}]).
recipe(steel_shield, 1, smithing, 18, [stack{tag: steel_ingot, qty: 3}, stack{tag: timber, qty: 1}]).
recipe(tower_shield, 1, smithing, 25, [stack{tag: steel_ingot, qty: 5}, stack{tag: timber, qty: 2}]).
recipe(aegis, 1, smithing, 70, [stack{tag: gold_ingot, qty: 4}, stack{tag: sunstone, qty: 2}, stack{tag: steel_ingot, qty: 5}]).

station(smithing, forge).
station(tailoring, loom).
station(woodworking, workbench).
station(alchemy, laboratory).
