:- module(spawn_config, [
    mob_xp/2, loot_table/5, race_bonus/3, is_aggressive/1
]).

mob_xp(rat, 10).
mob_xp(wolf, 40).
mob_xp(goblin, 25).
mob_xp(orc, 60).
mob_xp(dragon, 2000).
mob_xp(_, 20).

loot_table(rat, gold, 0.3, 1, 3).
loot_table(wolf, gold, 0.1, 1, 5).
loot_table(wolf, meat, 0.8, 1, 2).
loot_table(goblin, gold, 0.8, 3, 12).
loot_table(goblin, dagger, 0.1, 1, 1).
loot_table(orc, gold, 0.9, 8, 25).
loot_table(dragon, gold, 1.0, 500, 2000).
loot_table(dragon, sword, 0.5, 1, 1).

race_bonus(human, str, 2).
race_bonus(human, dex, 2).
race_bonus(human, int, 2).
race_bonus(elf, dex, 4).
race_bonus(elf, int, 3).
race_bonus(dwarf, str, 4).
race_bonus(dwarf, con, 5).

is_aggressive(wolf).
is_aggressive(goblin).
is_aggressive(orc).
is_aggressive(dragon).
is_aggressive(skeleton).
is_aggressive(zombie).
is_aggressive(wraith).
is_aggressive(imp).
is_aggressive(salamander).
is_aggressive(rock_worm).
is_aggressive(giant_spider).
is_aggressive(bear).
