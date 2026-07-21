:- module(cfg_race, [
    race_bonus/3,
    race_prop/2,
    restricted_race/1,
    special_player/1,
    base_ceiling/3,
    growth/3
]).

race_bonus(orc, str, 5).
race_bonus(dwarf, dex, 5).
race_bonus(human, int, 5).
race_bonus(elf, dex, 3).
race_bonus(demon, str, 10).
race_bonus(demon, int, 5).
race_bonus(angel, int, 10).
race_bonus(angel, dex, 5).
race_bonus(demigod, str, 15).
race_bonus(demigod, dex, 15).
race_bonus(demigod, int, 15).
race_bonus(_, _, 0).

race_prop(elf, night_vision).
race_prop(orc, regen).
race_prop(demon, fire_immune).
race_prop(angel, flight).
race_prop(demigod, night_vision).

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

growth(fighter, str, 3).
growth(fighter, dex, 2).
growth(fighter, int, 1).
growth(wizard, str, 1).
growth(wizard, dex, 2).
growth(wizard, int, 3).
