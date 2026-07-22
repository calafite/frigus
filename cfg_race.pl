:- module(cfg_race, [
    race_bonus/3,
    race_prop/2,
    restricted_race/1,
    special_player/1,
    base_ceiling/3,
    growth/3
]).

race_bonus(human, str, 2).
race_bonus(human, dex, 2).
race_bonus(human, int, 2).

race_bonus(elf, dex, 3).
race_bonus(elf, int, 2).
race_bonus(elf, str, -1).

race_bonus(dwarf, str, 3).
race_bonus(dwarf, dex, 2).
race_bonus(dwarf, int, -1).

race_bonus(orc, str, 5).
race_bonus(orc, int, -2).
race_bonus(orc, dex, 0).

race_bonus(goblin, dex, 4).
race_bonus(goblin, str, -2).

race_bonus(halfling, dex, 3).
race_bonus(halfling, int, 2).
race_bonus(halfling, str, -2).

race_bonus(draconian, str, 3).
race_bonus(draconian, int, 2).
race_bonus(draconian, dex, -1).

race_bonus(beastkin, dex, 3).
race_bonus(beastkin, str, 2).
race_bonus(beastkin, int, -1).

race_bonus(merfolk, str, 2).
race_bonus(merfolk, dex, 2).
race_bonus(merfolk, int, 1).

race_bonus(golem, str, 5).
race_bonus(golem, dex, -2).
race_bonus(golem, int, -2).

race_bonus(undead, str, 3).
race_bonus(undead, int, 3).
race_bonus(undead, dex, -2).

race_bonus(troll, str, 6).
race_bonus(troll, dex, -2).
race_bonus(troll, int, -3).

race_bonus(gnome, int, 4).
race_bonus(gnome, dex, 1).
race_bonus(gnome, str, -2).

race_bonus(tiefling, int, 3).
race_bonus(tiefling, dex, 2).
race_bonus(tiefling, str, -1).

race_bonus(giant, str, 8).
race_bonus(giant, dex, -3).
race_bonus(giant, int, -3).

race_bonus(demon, str, 10).
race_bonus(demon, dex, 5).
race_bonus(demon, int, 10).

race_bonus(angel, str, 5).
race_bonus(angel, dex, 10).
race_bonus(angel, int, 10).

race_bonus(demigod, str, 15).
race_bonus(demigod, dex, 15).
race_bonus(demigod, int, 15).

race_bonus(_, _, 0).

% Race Properties
race_prop(elf, night_vision).
race_prop(dwarf, poison_immune).
race_prop(dwarf, night_vision).
race_prop(orc, regen).
race_prop(goblin, night_vision).
race_prop(halfling, stealthy).
race_prop(draconian, fire_immune).
race_prop(beastkin, night_vision).
race_prop(merfolk, swimming).
race_prop(golem, poison_immune).
race_prop(golem, bloodless).
race_prop(undead, poison_immune).
race_prop(undead, bloodless).
race_prop(undead, night_vision).
race_prop(troll, regen).
race_prop(gnome, night_vision).
race_prop(tiefling, fire_immune).
race_prop(tiefling, night_vision).

% Broken properties
race_prop(demon, fire_immune).
race_prop(demon, night_vision).
race_prop(angel, flight).
race_prop(demigod, night_vision).
race_prop(demigod, regen).
race_prop(demigod, fire_immune).
race_prop(demigod, poison_immune).
race_prop(demigod, bloodless).
race_prop(demigod, cold_immune).

restricted_race(demon).
restricted_race(angel).
restricted_race(demigod).

special_player(sa).
special_player(miguel).

base_ceiling(fighter, str, 40).
base_ceiling(fighter, dex, 35).
base_ceiling(fighter, int, 20).
base_ceiling(wizard, str, 20).
base_ceiling(wizard, dex, 30).
base_ceiling(wizard, int, 45).
base_ceiling(rogue, str, 25).
base_ceiling(rogue, dex, 45).
base_ceiling(rogue, int, 25).
base_ceiling(cleric, str, 30).
base_ceiling(cleric, dex, 20).
base_ceiling(cleric, int, 40).

growth(fighter, str, 3).
growth(fighter, dex, 2).
growth(fighter, int, 1).
growth(wizard, str, 1).
growth(wizard, dex, 2).
growth(wizard, int, 3).
growth(rogue, str, 1).
growth(rogue, dex, 3).
growth(rogue, int, 2).
growth(cleric, str, 2).
growth(cleric, dex, 1).
growth(cleric, int, 3).
