:- module(cfg_item, [
    slot/2, weight/2, consumable/2,
    val/2, rarity/2, armor_val/2, soulbound/1
]).

slot(fists, wpn).
slot(sword, wpn).
slot(poison_dagger, wpn).
slot(staff, wpn).
slot(dagger, wpn).
slot(greatsword, wpn).
slot(battleaxe, wpn).
slot(longbow, wpn).
slot(shortbow, wpn).
slot(crossbow, wpn).
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

slot(wooden_shield, shield).
slot(iron_shield, shield).
slot(steel_shield, shield).
slot(tower_shield, shield).
slot(aegis, shield).

slot(rags, body).
slot(tunic, body).
slot(gambeson, body).
slot(leather_vest, body).
slot(leather_armor, body).
slot(studded_leather, body).
slot(brigandine, body).
slot(chainmail, body).
slot(scale_mail, body).
slot(half_plate, body).
slot(plate_mail, body).
slot(robes, body).
slot(bone_armor, body).

slot(_, none).

weight(gold, 0).
weight(fists, 0).
weight(sword, 4).
weight(poison_dagger, 2).
weight(staff, 3).
weight(dagger, 1).
weight(greatsword, 12).
weight(battleaxe, 8).
weight(longbow, 3).
weight(shortbow, 2).
weight(crossbow, 6).
weight(magic_wand, 1).
weight(wooden_club, 4).
weight(bronze_dagger, 2).
weight(bronze_sword, 5).
weight(iron_mace, 7).
weight(iron_spear, 6).
weight(steel_claymore, 14).
weight(steel_halberd, 12).
weight(composite_bow, 4).
weight(excalibur, 6).
weight(shadowfang, 2).
weight(gungnir, 7).
weight(mjolnir, 20).
weight(solaris, 8).

weight(wooden_shield, 5).
weight(iron_shield, 12).
weight(steel_shield, 15).
weight(tower_shield, 25).
weight(aegis, 20).

weight(rags, 1).
weight(tunic, 2).
weight(gambeson, 4).
weight(leather_vest, 5).
weight(leather_armor, 8).
weight(studded_leather, 10).
weight(brigandine, 15).
weight(chainmail, 20).
weight(scale_mail, 25).
weight(half_plate, 35).
weight(plate_mail, 50).
weight(robes, 3).
weight(bone_armor, 12).

weight(health_potion, 1).
weight(mana_potion, 1).
weight(elixir_of_life, 1).
weight(potion_of_haste, 1).
weight(potion_of_stoneskin, 1).
weight(deadly_poison, 1).

weight(raw_meat, 2).
weight(raw_fish, 1).
weight(apple, 1).
weight(bread, 1).
weight(cooked_meat, 2).
weight(cooked_fish, 1).

weight(iron_ore, 4).
weight(gold_ore, 4).
weight(silver_ore, 4).
weight(copper_ore, 4).
weight(coal, 2).
weight(timber, 5).
weight(iron_ingot, 3).
weight(gold_ingot, 3).
weight(silver_ingot, 3).

weight(wolf_pelt, 3).
weight(bear_pelt, 6).
weight(dragon_scale, 10).
weight(spider_silk, 1).
weight(shadow_essence, 0).
weight(holy_water, 1).
weight(_, 1).

val(gold, 1).
val(sword, 25).
val(dagger, 10).
val(greatsword, 60).
val(longbow, 35).
val(magic_wand, 80).
val(iron_mace, 40).
val(steel_claymore, 120).
val(excalibur, 5000).
val(mjolnir, 6000).

val(wooden_shield, 15).
val(iron_shield, 45).
val(tower_shield, 150).
val(aegis, 4000).

val(leather_armor, 30).
val(chainmail, 100).
val(plate_mail, 400).
val(robes, 20).

val(health_potion, 15).
val(mana_potion, 20).
val(elixir_of_life, 250).
val(deadly_poison, 100).

val(raw_meat, 3).
val(cooked_meat, 8).
val(apple, 1).
val(bread, 2).

val(iron_ore, 5).
val(gold_ore, 25).
val(timber, 2).
val(iron_ingot, 15).
val(gold_ingot, 80).
val(dragon_scale, 300).
val(shadow_essence, 150).
val(_, 1).

rarity(excalibur, 5).
rarity(mjolnir, 5).
rarity(solaris, 5).
rarity(gungnir, 5).
rarity(aegis, 5).
rarity(elixir_of_life, 4).
rarity(dragon_scale, 4).
rarity(shadow_essence, 4).
rarity(plate_mail, 3).
rarity(steel_claymore, 3).
rarity(gold_ingot, 3).
rarity(chainmail, 2).
rarity(iron_mace, 2).
rarity(health_potion, 1).
rarity(_, 0).

armor_val(rags, 1).
armor_val(tunic, 2).
armor_val(gambeson, 4).
armor_val(leather_vest, 5).
armor_val(leather_armor, 8).
armor_val(studded_leather, 10).
armor_val(brigandine, 14).
armor_val(chainmail, 18).
armor_val(scale_mail, 22).
armor_val(half_plate, 28).
armor_val(plate_mail, 35).
armor_val(robes, 3).
armor_val(bone_armor, 12).
armor_val(_, 0).

consumable(health_potion, heal(30)).
consumable(greater_health_potion, heal(80)).
consumable(mana_potion, buff(mp_regen, 10, 5)).
consumable(potion_of_haste, buff(haste, 0, 10)).
consumable(potion_of_stoneskin, buff(body, 20, 15)).
consumable(potion_of_invisibility, buff(hidden, 50, 10)).
consumable(elixir_of_life, heal(9999)).

soulbound(excalibur).
soulbound(mjolnir).
soulbound(solaris).
soulbound(gungnir).
soulbound(aegis).
