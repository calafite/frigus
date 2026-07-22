:- module(config, [
    dmg/2, cost/2, slot/2, weight/2, desc/2,
    consumable/2, val/2, rarity/2, inflicts/4,
    enemy/2, ally/2, req/3, scale/3, growth/3, mob_xp/2,
    loot_table/5, armor_val/2, cooldown/2,
    race_bonus/3, race_prop/2, restricted_race/1,
    special_player/1, spell_nature/2, req_race/2,
    base_ceiling/3, aggression/2, habitat/2,
    soulbound/1, aoe/1, friendly_fire_enabled/1, summon/2
]).

:- reexport(cfg_combat).
:- reexport(cfg_item).
:- reexport(cfg_magic).
:- reexport(cfg_mob).
:- reexport(cfg_race).
:- reexport(cfg_fac).
