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
weight(bronze_dagger, 1).
weight(bronze_sword, 3).
weight(iron_mace, 6).
weight(iron_spear, 5).
weight(steel_claymore, 10).
weight(steel_halberd, 9).
weight(composite_bow, 4).
weight(excalibur, 6).
weight(shadowfang, 2).
weight(gungnir, 5).
weight(mjolnir, 25).
weight(solaris, 3).
weight(shield, 5).
weight(tower_shield, 10).
weight(robe, 2).
weight(leather_vest, 4).
weight(leather_armor, 6).
weight(plate_mail, 20).
weight(potion, 1).
weight(str_potion, 1).
weight(bear_pelt, 5).
weight(spider_venom, 1).
weight(griffin_feather, 1).
weight(beef, 2).
weight(pork, 2).
weight(mutton, 2).
weight(venison, 2).
weight(chicken_meat, 1).
weight(leather, 3).
weight(feather, 1).
weight(wool, 2).
weight(snake_skin, 1).

desc(potion, "A bubbling red liquid.").
desc(str_potion, "A thick, metallic tasting draught.").
desc(sword, "A standard iron blade.").
desc(dagger, "A concealed, razor-sharp steel dagger.").
desc(greatsword, "A massive, heavy two-handed sword.").
desc(battleaxe, "A heavy steel axe built for cleaving.").
desc(longbow, "A sturdy yew bow built for distance firing.").
desc(magic_wand, "A slender wand huming with latent intellect.").
desc(wooden_club, "A heavy wooden branch fashioned into a crude club.").
desc(bronze_dagger, "A simple dagger cast from bronze.").
desc(bronze_sword, "A standard shortsword hammered from bronze.").
desc(iron_mace, "A brutal, spiked mace forged from iron.").
desc(iron_spear, "A reliable hunting spear tipped with an iron point.").
desc(steel_claymore, "A massive, finely balanced two-handed claymore of steel.").
desc(steel_halberd, "A long polearm combining an axe and a spear head.").
desc(composite_bow, "A recurve bow crafted from laminated horn, wood, and sinew.").
desc(excalibur, "The fabled sword of kings, radiating a pure golden aura.").
desc(shadowfang, "A dark dagger carved from obsidian that drips with poison.").
desc(gungnir, "The legendary spear of Odin, weighted to never miss its mark.").
desc(mjolnir, "The crushing hammer of thunder, forged in the heart of a dying star.").
desc(solaris, "A divine sword of pure solar flame, blinding to look upon.").
desc(beef, "A raw cut of beef.").
desc(pork, "A raw pork chop.").
desc(mutton, "A raw cut of mutton.").
desc(venison, "A raw cut of venison.").
desc(chicken_meat, "A raw chicken breast.").
desc(leather, "Cured, tough animal hide.").
desc(feather, "A soft, white bird feather.").
desc(wool, "A thick clump of raw sheep wool.").
desc(snake_skin, "A scaly, patterned snake skin.").

consumable(potion, heal(15)).
consumable(str_potion, buff(str, 5, 10)).
consumable(beef, heal(8)).
consumable(pork, heal(8)).
consumable(mutton, heal(6)).
consumable(venison, heal(10)).
consumable(chicken_meat, heal(4)).

val(potion, 10).
val(str_potion, 25).
val(sword, 50).
val(dagger, 15).
val(greatsword, 120).
val(battleaxe, 80).
val(longbow, 60).
val(magic_wand, 30).
val(wooden_club, 2).
val(bronze_dagger, 10).
val(bronze_sword, 25).
val(iron_mace, 45).
val(iron_spear, 40).
val(steel_claymore, 90).
val(steel_halberd, 100).
val(composite_bow, 80).
val(excalibur, 500).
val(shadowfang, 450).
val(gungnir, 600).
val(mjolnir, 2000).
val(solaris, 2500).
val(robe, 20).
val(leather_vest, 20).
val(leather_armor, 40).
val(plate_mail, 250).
val(tower_shield, 100).
val(poison_dagger, 150).
val(bear_pelt, 30).
val(spider_venom, 25).
val(griffin_feather, 15).
val(beef, 8).
val(pork, 8).
val(mutton, 6).
val(venison, 10).
val(chicken_meat, 4).
val(leather, 15).
val(feather, 1).
val(wool, 10).
val(snake_skin, 20).

rarity(gold, 0).
rarity(potion, 1).
rarity(sword, 2).
rarity(greatsword, 3).
rarity(plate_mail, 3).
rarity(excalibur, 4).
rarity(shadowfang, 4).
rarity(gungnir, 4).
rarity(poison_dagger, 4).
rarity(mjolnir, 5).
rarity(solaris, 5).
rarity(spider_venom, 2).
rarity(griffin_feather, 3).
rarity(_, 1).

armor_val(leather_vest, 3).
armor_val(robe, 2).
armor_val(leather_armor, 6).
armor_val(plate_mail, 15).
armor_val(shield, 5).
armor_val(tower_shield, 10).

soulbound(heirloom_sword).
soulbound(pendant).
soulbound(gold).
soulbound(mjolnir).
soulbound(solaris).
