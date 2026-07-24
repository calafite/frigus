:- module(spawn_config, [
    mob_xp/2, loot_table/5, race_bonus/3, race_trait/2, is_aggressive/1, mob_stats/5
]).

% Experience Points yield based on base tag
mob_xp(rat, 10).
mob_xp(wolf, 40).
mob_xp(bear, 80).
mob_xp(viper, 30).
mob_xp(giant_spider, 60).
mob_xp(dire_wolf, 90).
mob_xp(goblin, 25).
mob_xp(orc, 60).
mob_xp(hobgoblin, 50).
mob_xp(bandit, 45).
mob_xp(skeleton, 35).
mob_xp(zombie, 40).
mob_xp(wraith, 75).
mob_xp(lich, 200).
mob_xp(imp, 30).
mob_xp(hellhound, 70).
mob_xp(demon_brute, 150).
mob_xp(salamander, 65).
mob_xp(rock_worm, 80).
mob_xp(gargoyle, 90).
mob_xp(iron_golem, 120).
mob_xp(arcane_anomaly, 55).
mob_xp(treant, 110).
mob_xp(dragon, 2000).

% Structure Anomaly Boss XP Yields
mob_xp(elder_dragon, 3000).
mob_xp(swamp_hag, 1200).
mob_xp(ruin_golem, 1800).
mob_xp(ancient_treant_lord, 2000).
mob_xp(vampire_lord, 2200).
mob_xp(void_walker, 1600).
mob_xp(arch_necromancer, 2500).
mob_xp(_, 20).

% mob_stats(Tag, BaseHp, BaseStr, BaseDex, BaseInt)
mob_stats(rat, 10, 5, 10, 2).
mob_stats(wolf, 25, 12, 14, 4).
mob_stats(bear, 50, 18, 8, 4).
mob_stats(viper, 15, 8, 18, 2).
mob_stats(giant_spider, 35, 14, 16, 5).
mob_stats(dire_wolf, 45, 16, 15, 5).
mob_stats(skeleton, 20, 10, 10, 2).
mob_stats(zombie, 40, 14, 4, 1).
mob_stats(wraith, 30, 8, 18, 15).
mob_stats(lich, 80, 10, 12, 30).
mob_stats(goblin, 20, 8, 15, 8).
mob_stats(orc, 45, 16, 10, 6).
mob_stats(hobgoblin, 35, 14, 12, 10).
mob_stats(bandit, 25, 12, 14, 10).
mob_stats(imp, 15, 6, 16, 14).
mob_stats(hellhound, 40, 15, 15, 6).
mob_stats(demon_brute, 100, 22, 10, 8).
mob_stats(salamander, 30, 12, 12, 10).
mob_stats(rock_worm, 55, 16, 6, 2).
mob_stats(gargoyle, 50, 15, 8, 8).
mob_stats(iron_golem, 90, 20, 5, 2).
mob_stats(arcane_anomaly, 25, 4, 15, 20).
mob_stats(treant, 70, 18, 6, 12).
mob_stats(dragon, 500, 30, 20, 25).

% Structure Anomaly Boss Baseline Stats
mob_stats(elder_dragon, 600, 35, 20, 30).
mob_stats(swamp_hag, 250, 12, 18, 35).
mob_stats(ruin_golem, 500, 32, 10, 15).
mob_stats(ancient_treant_lord, 550, 28, 10, 20).
mob_stats(vampire_lord, 400, 28, 28, 25).
mob_stats(void_walker, 320, 18, 28, 38).
mob_stats(arch_necromancer, 380, 16, 20, 42).
mob_stats(_, 20, 10, 10, 10). % fallback

% Core Loot Tables
loot_table(rat, gold, 0.3, 1, 3).
loot_table(wolf, gold, 0.1, 1, 5).
loot_table(wolf, meat, 0.8, 1, 2).
loot_table(bear, meat, 1.0, 2, 5).
loot_table(bear, gold, 0.2, 5, 10).
loot_table(giant_spider, gold, 0.4, 2, 8).
loot_table(dire_wolf, meat, 1.0, 3, 6).
loot_table(goblin, gold, 0.8, 3, 12).
loot_table(goblin, dagger, 0.1, 1, 1).
loot_table(orc, gold, 0.9, 8, 25).
loot_table(orc, battleaxe, 0.05, 1, 1).
loot_table(hobgoblin, gold, 0.9, 10, 30).
loot_table(bandit, gold, 1.0, 15, 40).
loot_table(bandit, shortsword, 0.1, 1, 1).
loot_table(skeleton, gold, 0.5, 2, 10).
loot_table(zombie, gold, 0.4, 3, 12).
loot_table(wraith, gold, 0.7, 10, 35).
loot_table(lich, gold, 1.0, 50, 200).
loot_table(imp, gold, 0.6, 5, 15).
loot_table(hellhound, gold, 0.7, 12, 30).
loot_table(demon_brute, gold, 1.0, 40, 120).
loot_table(salamander, gold, 0.8, 10, 25).
loot_table(rock_worm, gold, 0.8, 15, 40).
loot_table(gargoyle, gold, 0.9, 20, 50).
loot_table(iron_golem, gold, 1.0, 30, 80).
loot_table(arcane_anomaly, gold, 0.9, 15, 45).
loot_table(treant, gold, 0.5, 10, 40).
loot_table(dragon, gold, 1.0, 500, 2000).

% Structure Boss Unique Loot Drops
loot_table(elder_dragon, gold, 1.0, 800, 2500).
loot_table(elder_dragon, dragon_heart, 0.8, 1, 1).
loot_table(elder_dragon, dragon_scale_mail, 0.5, 1, 1).

loot_table(swamp_hag, gold, 1.0, 300, 800).
loot_table(swamp_hag, witch_brew, 1.0, 1, 3).

loot_table(ruin_golem, gold, 1.0, 400, 1200).
loot_table(ruin_golem, ancient_core, 0.9, 1, 2).
loot_table(ruin_golem, ancient_runesword, 0.4, 1, 1).

loot_table(ancient_treant_lord, gold, 1.0, 350, 1000).
loot_table(ancient_treant_lord, treant_heartwood, 0.9, 1, 2).
loot_table(ancient_treant_lord, living_bark_shield, 0.5, 1, 1).

loot_table(vampire_lord, gold, 1.0, 600, 1800).
loot_table(vampire_lord, blood_ruby, 0.8, 1, 2).
loot_table(vampire_lord, vampire_fanged_blade, 0.5, 1, 1).

loot_table(void_walker, gold, 1.0, 450, 1400).
loot_table(void_walker, astral_shard, 0.9, 1, 3).
loot_table(void_walker, void_robe, 0.5, 1, 1).

loot_table(arch_necromancer, gold, 1.0, 700, 2000).
loot_table(arch_necromancer, necromancer_staff, 0.6, 1, 1).

% Balanced Lineage Bonuses
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

% Aggressiveness Flags
is_aggressive(wolf).
is_aggressive(bear).
is_aggressive(viper).
is_aggressive(giant_spider).
is_aggressive(dire_wolf).
is_aggressive(goblin).
is_aggressive(orc).
is_aggressive(hobgoblin).
is_aggressive(bandit).
is_aggressive(skeleton).
is_aggressive(zombie).
is_aggressive(wraith).
is_aggressive(lich).
is_aggressive(imp).
is_aggressive(hellhound).
is_aggressive(demon_brute).
is_aggressive(salamander).
is_aggressive(rock_worm).
is_aggressive(gargoyle).
is_aggressive(iron_golem).
is_aggressive(arcane_anomaly).
is_aggressive(treant).
is_aggressive(dragon).

% Structure Anomaly Bosses
is_aggressive(elder_dragon).
is_aggressive(swamp_hag).
is_aggressive(ruin_golem).
is_aggressive(ancient_treant_lord).
is_aggressive(vampire_lord).
is_aggressive(void_walker).
is_aggressive(arch_necromancer).
