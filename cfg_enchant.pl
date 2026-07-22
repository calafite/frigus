:- module(cfg_enchant, [
    rune_stat/3,
    repair_kit/2,
    scroll_type/1
]).

rune_stat(rune_of_fire, str, 5).
rune_stat(rune_of_ice, dex, 5).
rune_stat(rune_of_life, max_hp, 20).
rune_stat(rune_of_mana, max_mp, 20).
rune_stat(rune_of_strength, str, 8).
rune_stat(rune_of_agility, dex, 8).
rune_stat(rune_of_wisdom, int, 8).
rune_stat(minor_rune_of_strength, str, 3).
rune_stat(minor_rune_of_agility, dex, 3).
rune_stat(minor_rune_of_wisdom, int, 3).
rune_stat(master_rune_of_war, str, 15).
rune_stat(master_rune_of_shadows, dex, 15).
rune_stat(master_rune_of_arcana, int, 15).
rune_stat(rune_of_the_titan, armor, 10).

repair_kit(whetstone, wpn).
repair_kit(master_whetstone, wpn).
repair_kit(armor_patch, body).
repair_kit(heavy_armor_kit, body).
repair_kit(shield_brace, shield).

scroll_type(scroll_of_identify).
scroll_type(scroll_of_uncursing).
scroll_type(scroll_of_town_portal).
