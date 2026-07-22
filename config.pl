:- module(config, [
    dmg/2, cost/2, slot/2, weight/2, desc/2,
    consumable/2, val/2, rarity/2, inflicts/4,
    enemy/2, ally/2, req/3, scale/3, growth/3, mob_xp/2,
    loot_table/5, armor_val/2, cooldown/2,
    race_bonus/3, race_prop/2, restricted_race/1,
    special_player/1, spell_nature/2, req_race/2,
    base_ceiling/3, aggression/2, habitat/2,
    soulbound/1, aoe/1, friendly_fire_enabled/1, summon/2,
    is_utility_spell/1, gem_effect/3, slot_group/2, rune_stat/3,
    repair_kit/2, scroll_type/1, deity/2, altar/2, sac_val/2,
    blessing/3, crop_data/3, tamable/2, pet_food/2, struct_data/4,
    ingredient_aspect/2, potion_recipe/2,
    base_wpn/1, base_arm/1, base_acc/1, pref/4, suff/4, tier_mult/2,
    ammo/2
]).

:- reexport(cfg_combat).
:- reexport(cfg_item).
:- reexport(cfg_magic).
:- reexport(cfg_mob).
:- reexport(cfg_race).
:- reexport(cfg_fac).
:- reexport(cfg_enchant).
:- reexport(cfg_socket).
:- reexport(cfg_deity).
:- reexport(cfg_nature).
:- reexport(cfg_build).
:- reexport(cfg_alchemy).
:- reexport(cfg_proc_loot).
