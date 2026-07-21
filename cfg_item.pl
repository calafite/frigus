:- module(cfg_item, [
    slot/2,
    weight/2,
    desc/2,
    consumable/2,
    val/2,
    rarity/2,
    armor_val/2,
    soulbound/1
]).

slot(sword, wpn).
slot(poison_dagger, wpn).
slot(staff, wpn).
slot(dagger, wpn).
slot(greatsword, wpn).
slot(battleaxe, wpn).
slot(longbow, wpn).
slot(magic_wand, wpn).
slot(wooden_club, wpn).
slot(bronze_dagger, wpn).
slot(bronze_sword, wpn).
slot(iron_mace, wpn).
slot(iron_spear, wpn).
slot(steel_claymore, wpn).
slot(steel_halberd, wpn).
slot(composite_bow, wpn).
slot(excalibur, wpn).
slot(shadowfang, wpn).
slot(gungnir, wpn).
slot(mjolnir, wpn).
slot(solaris, wpn).
slot(shield, shield).
slot(tower_shield, shield).
slot(robe, body).
slot(leather_vest, body).
slot(leather_armor, body).
slot(plate_mail, body).
slot(iron_ore, none).
slot(copper_ore, none).
slot(silver_ore, none).
slot(gold_ore, none).
slot(coal, none).
slot(timber, none).
slot(sulfur, none).
slot(blue_lotus, none).
slot(fire_lily, none).
slot(iron_ingot, none).
slot(steel_ingot, none).
slot(silver_ingot, none).
slot(gold_ingot, none).
slot(electrum_ingot, none).
slot(sunstone, none).
slot(shadow_essence, none).
slot(basilisk_claw, none).
slot(antidote, none).
slot(elixir_of_life, none).
slot(haste_potion, none).
slot(mana_potion, none).

weight(gold, 0).
weight(fists, 0).
weight(sword, 4).
weight(poison_dagger, 2).
weight(staff, 2).
weight(dagger, 1).
weight(greatsword, 12).
weight(battleaxe, 8).
weight(longbow, 3).
weight(magic_wand, 1).
weight(wooden_club, 3).
weight(bronze_
