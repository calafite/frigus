:- module(cfg_proc_loot, [
    base_wpn/1, base_arm/1, base_acc/1,
    pref/4, suff/4, tier_mult/2
]).

base_wpn(dagger).
base_wpn(shortsword).
base_wpn(sword).
base_wpn(greatsword).
base_wpn(battleaxe).
base_wpn(iron_mace).
base_wpn(iron_spear).
base_wpn(steel_claymore).
base_wpn(steel_halberd).
base_wpn(shortbow).
base_wpn(longbow).
base_wpn(composite_bow).
base_wpn(crossbow).
base_wpn(magic_wand).
base_wpn(staff).

base_arm(rags).
base_arm(tunic).
base_arm(gambeson).
base_arm(leather_vest).
base_arm(leather_armor).
base_arm(studded_leather).
base_arm(brigandine).
base_arm(chainmail).
base_arm(scale_mail).
base_arm(half_plate).
base_arm(plate_mail).
base_arm(robes).

base_acc(ring).
base_acc(amulet).
base_acc(necklace).
base_acc(talisman).

pref(savage, str, 2, 5).
pref(brutal, str, 4, 8).
pref(ruthless, str, 6, 12).
pref(swift, dex, 2, 5).
pref(agile, dex, 4, 8).
pref(phantom, dex, 6, 12).
pref(hardy, con, 2, 5).
pref(stout, con, 4, 8).
pref(indomitable, con, 6, 12).
pref(wise, int, 2, 5).
pref(mystic, int, 4, 8).
pref(omniscient, int, 6, 12).
pref(insightful, wis, 2, 5).
pref(prophetic, wis, 4, 8).
pref(enlightened, wis, 6, 12).
pref(charming, cha, 2, 5).
pref(radiant, cha, 4, 8).
pref(majestic, cha, 6, 12).
pref(lucky, luk, 2, 5).
pref(blessed, luk, 4, 8).
pref(fated, luk, 6, 12).

pref(sturdy, max_hp, 10, 25).
pref(immortal, max_hp, 40, 100).
pref(heavy, armor, 2, 8).
pref(impenetrable, armor, 10, 25).

suff(bear, str, 2, 5).
suff(titan, str, 5, 12).
suff(fox, dex, 2, 5).
suff(falcon, dex, 5, 12).
suff(ox, con, 2, 5).
suff(mountain, con, 5, 12).
suff(owl, int, 2, 5).
suff(dragon, int, 5, 12).
suff(seer, wis, 2, 5).
suff(oracle, wis, 5, 12).
suff(bard, cha, 2, 5).
suff(monarch, cha, 5, 12).
suff(fool, luk, 2, 5).
suff(trickster, luk, 5, 12).

suff(boar, max_hp, 15, 35).
suff(leech, lifesteal, 2, 6).
suff(aegis, armor, 8, 20).
suff(assassin, crit_chance, 2, 8).
suff(executioner, crit_mult, 20, 75).
suff(kings, all_stats, 2, 5).

tier_mult(1, 1.0).
tier_mult(2, 1.5).
tier_mult(3, 2.0).
tier_mult(4, 3.0).
tier_mult(5, 5.0).
