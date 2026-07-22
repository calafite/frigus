:- module(cfg_enchant, [
    rune_stat/3,
    repair_kit/2,
    scroll_type/1
]).

rune_stat(rune_of_strength, str, 5).
rune_stat(rune_of_power, str, 10).
rune_stat(rune_of_agility, dex, 5).
rune_stat(rune_of_swiftness, dex, 10).
rune_stat(rune_of_wisdom, wis, 5).
rune_stat(rune_of_enlightenment, wis, 10).
rune_stat(rune_of_intellect, int, 5).
rune_stat(rune_of_sage, int, 10).
rune_stat(rune_of_fortune, luk, 5).
rune_stat(rune_of_destiny, luk, 10).
rune_stat(rune_of_constitution, con, 5).
rune_stat(rune_of_colossus, con, 10).
rune_stat(rune_of_majesty, cha, 5).
rune_stat(rune_of_glory, cha, 10).

rune_stat(rune_of_embers, dmg(fire), 5).
rune_stat(rune_of_flames, dmg(fire), 12).
rune_stat(rune_of_frost, dmg(ice), 5).
rune_stat(rune_of_glaciers, dmg(ice), 12).
rune_stat(rune_of_sparks, dmg(lightning), 5).
rune_stat(rune_of_storms, dmg(lightning), 12).
rune_stat(rune_of_corruption, dmg(poison), 4).
rune_stat(rune_of_decay, dmg(poison), 10).
rune_stat(rune_of_sanctity, dmg(holy), 6).
rune_stat(rune_of_divinity, dmg(holy), 14).
rune_stat(rune_of_nether, dmg(dark), 6).
rune_stat(rune_of_abyss, dmg(dark), 14).

rune_stat(rune_of_sturdiness, max_hp, 25).
rune_stat(rune_of_vitality, max_hp, 60).
rune_stat(rune_of_mana_flow, max_mp, 20).
rune_stat(rune_of_archmage, max_mp, 50).
rune_stat(rune_of_iron, armor, 5).
rune_stat(rune_of_steel, armor, 15).
rune_stat(rune_of_warmth, cold_immune, 1).
rune_stat(rune_of_curing, poison_immune, 1).

rune_stat(rune_of_fire_ward, fire_resist, 15).
rune_stat(rune_of_ice_ward, ice_resist, 15).
rune_stat(rune_of_storm_ward, lightning_resist, 15).
rune_stat(rune_of_venom_ward, poison_resist, 20).
rune_stat(rune_of_light_ward, holy_resist, 15).
rune_stat(rune_of_shadow_ward, dark_resist, 15).

repair_kit(whetstone, wpn).
repair_kit(master_whetstone, wpn).
repair_kit(armor_patch, body).
repair_kit(heavy_armor_kit, body).
repair_kit(shield_brace, shield).

scroll_type(scroll_of_identify).
scroll_type(scroll_of_uncursing).
scroll_type(scroll_of_town_portal).
