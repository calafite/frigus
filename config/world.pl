:- module(world_config, [
    theme_weight/2, theme_data/2, rm_adj/2, rm_noun/2,
    base_wpn/1, base_arm/1, base_acc/1, pref/4, suff/4, tier_mult/2,
    mob_base/2, elite_mod/3, safe_zone_chance/2
]).

theme_weight(grove, 100).
theme_weight(forest, 100).
theme_weight(keep, 100).
theme_weight(cavern, 80).
theme_weight(mine, 80).
theme_weight(ruins, 80).
theme_weight(volcano, 20).
theme_weight(crypt, 20).

theme_data(crypt, [undead, dark]).
theme_data(cavern, [beast, earth]).
theme_data(ruins, [humanoid, magic]).
theme_data(keep, [humanoid, steel]).
theme_data(forest, [beast, nature]).
theme_data(mine, [beast, earth, steel]).
theme_data(volcano, [demon, fire, earth]).

rm_adj(crypt, [dusty, crumbling, desecrated, silent, echoing]).
rm_adj(cavern, [damp, dark, winding, massive, glowing]).
rm_adj(ruins, [overgrown, ancient, forgotten, shattered]).
rm_adj(keep, [fortified, ruined, grand, imposing]).
rm_adj(forest, [verdant, shadowy, ancient, dense]).
rm_adj(mine, [excavated, abandoned, collapsed, 'resource-rich']).
rm_adj(volcano, [magmatic, unstable, erupting, heated]).

rm_noun(crypt, [tomb, catacomb, sepulcher, vault, mausoleum]).
rm_noun(cavern, [cave, tunnel, grotto, chasm, hollow]).
rm_noun(ruins, [courtyard, plaza, remnants, rubble, hall]).
rm_noun(keep, [armory, barracks, throne_room, dungeon]).
rm_noun(forest, [glade, thicket, clearing, den, canopy]).
rm_noun(mine, [shaft, lode, elevator, excavation_site]).
rm_noun(volcano, [magma_chamber, vent, obsidian_spire, crater_edge]).

base_wpn(dagger).
base_wpn(shortsword).
base_wpn(sword).
base_wpn(greatsword).
base_wpn(battleaxe).
base_wpn(shortbow).
base_wpn(staff).

base_arm(rags).
base_arm(tunic).
base_arm(leather_vest).
base_arm(chainmail).
base_arm(plate_mail).

base_acc(ring).
base_acc(amulet).
base_acc(necklace).

pref(savage, str, 2, 5).
pref(swift, dex, 2, 5).
pref(wise, int, 2, 5).
pref(sturdy, max_hp, 10, 25).
pref(heavy, armor, 2, 8).

suff(bear, str, 2, 5).
suff(fox, dex, 2, 5).
suff(owl, int, 2, 5).
suff(boar, max_hp, 15, 35).

tier_mult(1, 1.0).
tier_mult(2, 1.5).
tier_mult(3, 2.0).
tier_mult(4, 3.0).

mob_base(undead, skeleton).
mob_base(undead, zombie).
mob_base(undead, wraith).
mob_base(beast, wolf).
mob_base(beast, bear).
mob_base(beast, giant_spider).
mob_base(humanoid, goblin).
mob_base(humanoid, orc).
mob_base(demon, imp).
mob_base(fire, salamander).
mob_base(earth, rock_worm).
mob_base(steel, iron_golem).

elite_mod(armored, armor, 2.0).
elite_mod(berserk, str, 2.5).
elite_mod(swift, dex, 2.5).
elite_mod(titan, max_hp, 3.0).

safe_zone_chance(village, 100).
safe_zone_chance(monastery, 100).
safe_zone_chance(grove, 0).
safe_zone_chance(forest, 0).
safe_zone_chance(wild, 0).
safe_zone_chance(_, 0).
