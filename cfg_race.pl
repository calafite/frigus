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
race_bonus(human, con, 2).
race_bonus(human, int, 2).
race_bonus(human, wis, 2).
race_bonus(human, cha, 2).
race_bonus(human, luk, 2).

race_bonus(elf, dex, 4).
race_bonus(elf, int, 3).
race_bonus(elf, wis, 3).
race_bonus(elf, cha, 3).
race_bonus(elf, str, -1).
race_bonus(elf, con, -1).
race_bonus(elf, luk, 0).

race_bonus(dwarf, str, 4).
race_bonus(dwarf, con, 5).
race_bonus(dwarf, wis, 2).
race_bonus(dwarf, cha, -2).
race_bonus(dwarf, dex, -1).
race_bonus(dwarf, int, 0).
race_bonus(dwarf, luk, 1).

race_bonus(orc, str, 6).
race_bonus(orc, con, 4).
race_bonus(orc, int, -2).
race_bonus(orc, wis, -1).
race_bonus(orc, cha, -3).
race_bonus(orc, luk, -1).
race_bonus(orc, dex, 0).

race_bonus(goblin, dex, 5).
race_bonus(goblin, luk, 4).
race_bonus(goblin, str, -2).
race_bonus(goblin, cha, -3).
race_bonus(goblin, con, -1).
race_bonus(goblin, wis, -1).
race_bonus(goblin, int, 0).

race_bonus(halfling, dex, 4).
race_bonus(halfling, cha, 4).
race_bonus(halfling, luk, 5).
race_bonus(halfling, str, -3).
race_bonus(halfling, con, -1).
race_bonus(halfling, int, 0).
race_bonus(halfling, wis, 1).

race_bonus(draconian, str, 5).
race_bonus(draconian, con, 4).
race_bonus(draconian, int, 3).
race_bonus(draconian, cha, 2).
race_bonus(draconian, dex, -1).
race_bonus(draconian, luk, -1).
race_bonus(draconian, wis, 0).

race_bonus(beastkin, dex, 4).
race_bonus(beastkin, str, 3).
race_bonus(beastkin, con, 3).
race_bonus(beastkin, wis, 3).
race_bonus(beastkin, int, -2).
race_bonus(beastkin, cha, -1).
race_bonus(beastkin, luk, 0).

race_bonus(merfolk, dex, 3).
race_bonus(merfolk, cha, 4).
race_bonus(merfolk, wis, 3).
race_bonus(merfolk, str, -1).
race_bonus(merfolk, con, 0).
race_bonus(merfolk, int, 1).
race_bonus(merfolk, luk, 1).

race_bonus(golem, str, 8).
race_bonus(golem, con, 8).
race_bonus(golem, dex, -4).
race_bonus(golem, int, -3).
race_bonus(golem, cha, -5).
race_bonus(golem, luk, -3).
race_bonus(golem, wis, 0).

race_bonus(undead, str, 3).
race_bonus(undead, con, 5).
race_bonus(undead, int, 3).
race_bonus(undead, cha, -5).
race_bonus(undead, luk, -3).
race_bonus(undead, dex, -1).
race_bonus(undead, wis, 1).

race_bonus(troll, str, 7).
race_bonus(troll, con, 6).
race_bonus(troll, int, -4).
race_bonus(troll, cha, -5).
race_bonus(troll, wis, -2).
race_bonus(troll, dex, -2).
race_bonus(troll, luk, 0).

race_bonus(gnome, int, 5).
race_bonus(gnome, wis, 3).
race_bonus(gnome, cha, 3).
race_bonus(gnome, luk, 3).
race_bonus(gnome, str, -3).
race_bonus(gnome, con, -2).
race_bonus(gnome, dex, 0).

race_bonus(tiefling, int, 4).
race_bonus(tiefling, cha, 5).
race_bonus(tiefling, dex, 2).
race_bonus(tiefling, luk, -2).
race_bonus(tiefling, str, -1).
race_bonus(tiefling, wis, 0).
race_bonus(tiefling, con, 0).

race_bonus(giant, str, 10).
race_bonus(giant, con, 8).
race_bonus(giant, dex, -5).
race_bonus(giant, int, -3).
race_bonus(giant, cha, -4).
race_bonus(giant, luk, -2).
race_bonus(giant, wis, -1).

race_bonus(demon, str, 10).
race_bonus(demon, int, 10).
race_bonus(demon, cha, 8).
race_bonus(demon, con, 8).
race_bonus(demon, dex, 5).
race_bonus(demon, wis, 2).
race_bonus(demon, luk, -5).

race_bonus(angel, wis, 12).
race_bonus(angel, cha, 10).
race_bonus(angel, int, 8).
race_bonus(angel, dex, 6).
race_bonus(angel, str, 5).
race_bonus(angel, con, 5).
race_bonus(angel, luk, 5).

race_bonus(demigod, str, 15).
race_bonus(demigod, dex, 15).
race_bonus(demigod, con, 15).
race_bonus(demigod, int, 15).
race_bonus(demigod, wis, 15).
race_bonus(demigod, cha, 15).
race_bonus(demigod, luk, 15).

race_bonus(_, _, 0).

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

base_ceiling(fighter, str, 45).
base_ceiling(fighter, dex, 35).
base_ceiling(fighter, con, 45).
base_ceiling(fighter, int, 20).
base_ceiling(fighter, wis, 25).
base_ceiling(fighter, cha, 30).
base_ceiling(fighter, luk, 30).

base_ceiling(wizard, str, 20).
base_ceiling(wizard, dex, 30).
base_ceiling(wizard, con, 25).
base_ceiling(wizard, int, 50).
base_ceiling(wizard, wis, 40).
base_ceiling(wizard, cha, 35).
base_ceiling(wizard, luk, 30).

base_ceiling(rogue, str, 25).
base_ceiling(rogue, dex, 50).
base_ceiling(rogue, con, 30).
base_ceiling(rogue, int, 25).
base_ceiling(rogue, wis, 25).
base_ceiling(rogue, cha, 40).
base_ceiling(rogue, luk, 45).

base_ceiling(cleric, str, 30).
base_ceiling(cleric, dex, 20).
base_ceiling(cleric, con, 35).
base_ceiling(cleric, int, 35).
base_ceiling(cleric, wis, 50).
base_ceiling(cleric, cha, 40).
base_ceiling(cleric, luk, 30).

growth(fighter, str, 4).
growth(fighter, dex, 2).
growth(fighter, con, 3).
growth(fighter, int, 1).
growth(fighter, wis, 1).
growth(fighter, cha, 2).
growth(fighter, luk, 1).

growth(wizard, str, 1).
growth(wizard, dex, 2).
growth(wizard, con, 1).
growth(wizard, int, 4).
growth(wizard, wis, 3).
growth(wizard, cha, 2).
growth(wizard, luk, 1).

growth(rogue, str, 1).
growth(rogue, dex, 4).
growth(rogue, con, 1).
growth(rogue, int, 1).
growth(rogue, wis, 1).
growth(rogue, cha, 3).
growth(rogue, luk, 3).

growth(cleric, str, 2).
growth(cleric, dex, 1).
growth(cleric, con, 2).
growth(cleric, int, 2).
growth(cleric, wis, 4).
growth(cleric, cha, 2).
growth(cleric, luk, 1).
