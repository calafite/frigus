:- module(cfg_socket, [
    gem_effect/3,
    slot_group/2
]).

slot_group(wpn, wpn).
slot_group(shield, shield).
slot_group(body, body).
slot_group(head, body).
slot_group(legs, body).
slot_group(hands, body).
slot_group(feet, body).

gem_effect(ruby, wpn, prop(dmg(fire), 8)).
gem_effect(ruby, shield, prop(fire_resist, 15)).
gem_effect(ruby, body, prop(max_hp, 30)).

gem_effect(sapphire, wpn, prop(dmg(ice), 8)).
gem_effect(sapphire, shield, prop(ice_resist, 15)).
gem_effect(sapphire, body, prop(max_mp, 25)).

gem_effect(topaz, wpn, prop(dmg(lightning), 8)).
gem_effect(topaz, shield, prop(lightning_resist, 15)).
gem_effect(topaz, body, prop(dex, 4)).

gem_effect(emerald, wpn, prop(dmg(poison), 6)).
gem_effect(emerald, shield, prop(poison_resist, 20)).
gem_effect(emerald, body, prop(con, 4)).

gem_effect(diamond, wpn, prop(dmg(holy), 10)).
gem_effect(diamond, shield, prop(holy_resist, 15)).
gem_effect(diamond, body, prop(wis, 4)).

gem_effect(onyx, wpn, prop(dmg(dark), 10)).
gem_effect(onyx, shield, prop(dark_resist, 15)).
gem_effect(onyx, body, prop(int, 4)).

gem_effect(skull, wpn, prop(lifesteal, 4)).
gem_effect(skull, shield, prop(armor, 8)).
gem_effect(skull, body, prop(str, 4)).

gem_effect(prism, wpn, prop(crit_chance, 5)).
gem_effect(prism, shield, prop(magic_resist, 15)).
gem_effect(prism, body, prop(luk, 5)).
