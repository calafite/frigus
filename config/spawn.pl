:- module(spawn_config, [
    mob_xp/2, loot_table/5, race_bonus/3, race_trait/2, is_aggressive/1
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
dragon_loot_table(dragon, sword, 0.5, 1, 1).


% Balanced
race_bonus(human, str, 2).
race_bonus(human, dex, 2).
race_bonus(human, con, 2).
race_bonus(human, int, 2).
race_bonus(human, wis, 2).
race_bonus(human, cha, 2).
race_bonus(human, luk, 2).

% Elven Lineages
race_bonus(elf, int, 6).
race_bonus(elf, wis, 4).
race_bonus(elf, dex, 6).
race_bonus(elf, str, -2).

race_bonus(high_elf, int, 8).
race_bonus(high_elf, wis, 6).
race_bonus(high_elf, dex, 4).
race_bonus(high_elf, str, -4).
race_bonus(high_elf, cha, 2).

race_bonus(wood_elf, dex, 8).
race_bonus(wood_elf, wis, 4).
race_bonus(wood_elf, luk, 4).
race_bonus(wood_elf, str, -2).
race_bonus(wood_elf, int, -2).

race_bonus(dark_elf, dex, 6).
race_bonus(dark_elf, int, 6).
race_bonus(dark_elf, luk, 2).
race_bonus(dark_elf, str, -2).
race_bonus(dark_elf, cha, -4).

% Hardy / Heavy
race_bonus(dwarf, con, 8).
race_bonus(dwarf, str, 4).
race_bonus(dwarf, dex, -2).

race_bonus(orc, str, 10).
race_bonus(orc, con, 4).
race_bonus(orc, int, -4).
race_bonus(orc, wis, -4).

% Small / Nimble / Crafty
race_bonus(goblin, dex, 8).
race_bonus(goblin, luk, 6).
race_bonus(goblin, str, -4).

race_bonus(kobold, dex, 6).
race_bonus(kobold, luk, 8).
race_bonus(kobold, str, -4).

race_bonus(halfling, luk, 10).
race_bonus(halfling, dex, 6).
race_bonus(halfling, cha, 4).
race_bonus(halfling, str, -6).
race_bonus(halfling, con, -2).

race_bonus(gnome, int, 8).
race_bonus(gnome, luk, 6).
race_bonus(gnome, wis, 2).
race_bonus(gnome, str, -6).

% Giant-Kin / Regenerative
race_bonus(giant, con, 14).
race_bonus(giant, str, 8).
race_bonus(giant, dex, -6).

race_bonus(ogre, con, 8).
race_bonus(ogre, str, 6).
race_bonus(ogre, int, -4).

race_bonus(troll, con, 16).
race_bonus(troll, str, 10).
race_bonus(troll, dex, -4).
race_bonus(troll, int, -8).
race_bonus(troll, wis, -8).
race_bonus(troll, cha, -8).

% Wild / Mystical
race_bonus(wolfkin, str, 6).
race_bonus(wolfkin, dex, 6).
race_bonus(wolfkin, con, 4).
race_bonus(wolfkin, int, -4).
race_bonus(wolfkin, cha, -2).

race_bonus(nymph, cha, 10).
race_bonus(nymph, wis, 6).
race_bonus(nymph, dex, 4).
race_bonus(nymph, str, -6).
race_bonus(nymph, con, -4).

% Celestial Lineages (Restricted / Overpowered)
race_bonus(angel, str, 25).
race_bonus(angel, dex, 25).
race_bonus(angel, con, 25).
race_bonus(angel, int, 25).
race_bonus(angel, wis, 25).
race_bonus(angel, cha, 25).
race_bonus(angel, luk, 25).

race_bonus(demon, str, 30).
race_bonus(demon, dex, 20).
race_bonus(demon, con, 25).
race_bonus(demon, int, 25).
race_bonus(demon, wis, 15).
race_bonus(demon, cha, 20).
race_bonus(demon, luk, 25).

% Lineage Traits
race_trait(goblin, quick).
race_trait(kobold, quick).
race_trait(wood_elf, quick).
race_trait(dark_elf, quick).
race_trait(halfling, quick).

race_trait(nymph, elusive).
race_trait(wolfkin, feral).
race_trait(high_elf, keen_mind).
race_trait(gnome, keen_mind).

race_trait(ogre, high_regen).
race_trait(troll, troll_regen).

race_trait(angel, celestial).
race_trait(demon, celestial).

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
