:- module(cfg_proc, [
    theme_data/2, rm_adj/2, rm_noun/2,
    base_wpn/1, base_arm/1, base_acc/1,
    pref/4, suff/4, tier_mult/2,
    mob_base/2, elite_mod/3, evt_mod/2
]).

theme_data(crypt, [undead, dark]).
theme_data(cavern, [beast, earth]).
theme_data(inferno, [demon, fire]).
theme_data(abyss, [void, dark]).
theme_data(ruins, [humanoid, magic]).
theme_data(keep, [humanoid, steel]).
theme_data(grove, [beast, nature]).
theme_data(tomb, [undead, magic]).
theme_data(volcano, [demon, fire, earth]).
theme_data(glacier, [beast, ice]).
theme_data(swamp, [beast, poison]).
theme_data(desert, [humanoid, fire, earth]).
theme_data(sewer, [beast, poison, dark]).
theme_data(sky, [humanoid, lightning]).
theme_data(void, [void, magic]).
theme_data(prison, [humanoid, dark]).
theme_data(asylum, [undead, void]).
theme_data(mine, [beast, earth, steel]).
theme_data(temple, [humanoid, holy]).
theme_data(sanctum, [void, holy, magic]).

rm_adj(crypt, [dusty, crumbling, desecrated, silent, echoing, bloodstained]).
rm_adj(cavern, [damp, dark, winding, massive, claustrophobic, glowing]).
rm_adj(inferno, [scorching, burning, ash-choked, blazing, molten, charred]).
rm_adj(abyss, [pitch-black, endless, mind-bending, shifting, silent, crushing]).
rm_adj(ruins, [overgrown, ancient, forgotten, shattered, majestic, cursed]).
rm_adj(keep, [fortified, ruined, grand, imposing, heavily-armed, strategic]).
rm_adj(grove, [verdant, corrupted, whispering, dense, sacred, ancient]).
rm_adj(tomb, [sealed, opulent, trapped, hollow, revered, haunted]).
rm_adj(volcano, [magmatic, unstable, erupting, suffocating, heated, jagged]).
rm_adj(glacier, [freezing, crystalline, slippery, reflective, howling, frozen]).
rm_adj(swamp, [fetid, murky, bubbling, toxic, stagnant, overgrown]).
rm_adj(desert, [sun-baked, arid, shifting, wind-swept, desolate, parched]).
rm_adj(sewer, [foul, echoing, dripping, rancid, flooded, diseased]).
rm_adj(sky, [cloud-obscured, floating, windy, blinding, ethereal, storm-tossed]).
rm_adj(void, [formless, alien, distorted, empty, silent, unnatural]).
rm_adj(prison, [bleak, iron-barred, despairing, secure, bloodied, inescapable]).
rm_adj(asylum, [manic, blood-spattered, haunting, padded, forsaken, twisted]).
rm_adj(mine, [excavated, abandoned, collapsed, resource-rich, echoing, dusty]).
rm_adj(temple, [holy, defiled, resplendent, ornate, towering, sacred]).
rm_adj(sanctum, [pure, glowing, arcane, silent, forbidden, warded]).

rm_noun(crypt, [tomb, catacomb, sepulcher, vault, mausoleum, burial chamber]).
rm_noun(cavern, [cave, tunnel, grotto, chasm, hollow, stalactite hall]).
rm_noun(inferno, [pit, caldera, lake of fire, forge, ash-waste, crater]).
rm_noun(abyss, [void, chasm, nothingness, rift, anomaly, depth]).
rm_noun(ruins, [courtyard, plaza, collapsed tower, remnants, rubble, hall]).
rm_noun(keep, [armory, barracks, throne room, battlements, dungeon, gatehouse]).
rm_noun(grove, [glade, thicket, clearing, den, canopy, root-chamber]).
rm_noun(tomb, [sarcophagus room, burial hall, ritual chamber, antechamber, false tomb, treasury]).
rm_noun(volcano, [magma chamber, vent, obsidian spire, lava tube, crater edge, forge]).
rm_noun(glacier, [ice cave, frozen lake, crevasse, frost-hall, crystal spire, tundra]).
rm_noun(swamp, [mire, bog, mud-pit, sunken ruin, rot-wood, hag-hut]).
rm_noun(desert, [dune, oasis, canyon, dry-riverbed, sandstone cave, mirage]).
rm_noun(sewer, [cistern, outflow, sludge-tunnel, maintenance shaft, rat-nest, drainage grate]).
rm_noun(sky, [cloud-island, wind-tunnel, apex, floating bridge, storm-eye, peak]).
rm_noun(void, [fracture, nexus, singularity, non-space, event horizon, paradox]).
rm_noun(prison, [cellblock, interrogation room, warden office, execution yard, solitary, mess hall]).
rm_noun(asylum, [ward, lobotomy room, straightjacket storage, isolation cell, common room, pharmacy]).
rm_noun(mine, [shaft, lode, elevator, cart-track, excavation site, dead-end]).
rm_noun(temple, [altar, nave, sanctuary, choir, belfry, reliquary]).
rm_noun(sanctum, [inner eye, mana pool, rune chamber, astrolabe, nexus, meditation room]).

base_wpn(dagger).
base_wpn(shortsword).
base_wpn(longsword).
base_wpn(claymore).
base_wpn(rapier).
base_wpn(katana).
base_wpn(scimitar).
base_wpn(warhammer).
base_wpn(mace).
base_wpn(flail).
base_wpn(maul).
base_wpn(battleaxe).
base_wpn(greataxe).
base_wpn(halberd).
base_wpn(glaive).
base_wpn(pike).
base_wpn(spear).
base_wpn(shortbow).
base_wpn(longbow).
base_wpn(crossbow).
base_wpn(wand).
base_wpn(staff).
base_wpn(orb).
base_wpn(tome).
base_wpn(scepter).

base_arm(rags).
base_arm(tunic).
base_arm(gambeson).
base_arm(leather_vest).
base_arm(studded_leather).
base_arm(brigandine).
base_arm(chainmail).
base_arm(scale_mail).
base_arm(half_plate).
base_arm(plate_mail).
base_arm(robes).
base_arm(cloak).
base_arm(mantle).
base_arm(heavy_cloak).
base_arm(bone_armor).

base_acc(ring).
base_acc(amulet).
base_acc(necklace).
base_acc(pendant).
base_acc(charm).
base_acc(talisman).
base_acc(bracelet).
base_acc(band).
base_acc(chain).
base_acc(brooch).

pref(savage, str, 2, 5).
pref(brutal, str, 4, 8).
pref(ruthless, str, 6, 12).
pref(swift, dex, 2, 5).
pref(agile, dex, 4, 8).
pref(phantom, dex, 6, 12).
pref(wise, int, 2, 5).
pref(mystic, int, 4, 8).
pref(omniscient, int, 6, 12).
pref(sturdy, max_hp, 10, 25).
pref(stalwart, max_hp, 20, 50).
pref(immortal, max_hp, 40, 100).
pref(fiery, fire_dmg, 2, 10).
pref(icy, ice_dmg, 2, 10).
pref(toxic, poison_dmg, 2, 10).
pref(static, lightning_dmg, 2, 10).
pref(holy, holy_dmg, 2, 10).
pref(dark, void_dmg, 2, 10).
pref(vampiric, lifesteal, 1, 5).
pref(radiant, hp_regen, 1, 5).
pref(heavy, armor, 2, 8).
pref(fortified, armor, 5, 15).
pref(impenetrable, armor, 10, 25).
pref(precise, crit_chance, 1, 5).
pref(lethal, crit_mult, 10, 50).

suff(bear, str, 2, 5).
suff(titan, str, 5, 12).
suff(fox, dex, 2, 5).
suff(falcon, dex, 5, 12).
suff(owl, int, 2, 5).
suff(dragon, int, 5, 12).
suff(boar, max_hp, 15, 35).
suff(behemoth, max_hp, 35, 80).
suff(flame, fire_dmg, 3, 12).
suff(winter, ice_dmg, 3, 12).
suff(viper, poison_dmg, 3, 12).
suff(storm, lightning_dmg, 3, 12).
suff(light, holy_dmg, 3, 12).
suff(shadow, void_dmg, 3, 12).
suff(leech, lifesteal, 2, 6).
suff(sun, hp_regen, 2, 6).
suff(mountain, armor, 4, 10).
suff(aegis, armor, 8, 20).
suff(assassin, crit_chance, 2, 8).
suff(executioner, crit_mult, 20, 75).
suff(kings, all_stats, 2, 5).
suff(gods, all_stats, 5, 10).
suff(stars, mp_regen, 2, 8).
suff(void, magic_resist, 5, 15).
suff(blood, phys_resist, 5, 15).

tier_mult(1, 1.0).
tier_mult(2, 1.5).
tier_mult(3, 2.0).
tier_mult(4, 3.0).
tier_mult(5, 5.0).

mob_base(undead, skeleton).
mob_base(undead, zombie).
mob_base(undead, wraith).
mob_base(undead, lich).
mob_base(beast, wolf).
mob_base(beast, bear).
mob_base(beast, giant_spider).
mob_base(beast, shadow_panther).
mob_base(demon, imp).
mob_base(demon, hellhound).
mob_base(demon, succubus).
mob_base(demon, balor).
mob_base(humanoid, goblin).
mob_base(humanoid, orc).
mob_base(humanoid, bandit).
mob_base(humanoid, dark_knight).
mob_base(magic, slime).
mob_base(magic, elemental).
mob_base(magic, golem).
mob_base(magic, homunculus).
mob_base(void, watcher).
mob_base(void, stalker).
mob_base(void, devourer).
mob_base(void, anomaly).
mob_base(fire, fire_sprite).
mob_base(fire, salamander).
mob_base(earth, rock_worm).
mob_base(earth, basilisk).
mob_base(ice, frost_wolf).
mob_base(ice, yeti).
mob_base(poison, snake).
mob_base(poison, plague_rat).
mob_base(steel, animated_armor).
mob_base(steel, iron_golem).
mob_base(nature, ent).
mob_base(nature, dryad).
mob_base(holy, zealot).
mob_base(holy, angel).

elite_mod(armored, armor, 2.0).
elite_mod(berserk, str, 2.5).
elite_mod(swift, dex, 2.5).
elite_mod(arcane, int, 2.5).
elite_mod(titan, max_hp, 3.0).
elite_mod(vampiric, lifesteal, 10.0).
elite_mod(venomous, poison_dmg, 5.0).
elite_mod(flaming, fire_dmg, 5.0).
elite_mod(frozen, ice_dmg, 5.0).
elite_mod(shocking, lightning_dmg, 5.0).
elite_mod(radiant, holy_dmg, 5.0).
elite_mod(corrupted, void_dmg, 5.0).
elite_mod(regenerating, hp_regen, 10.0).
elite_mod(lethal, crit_chance, 15.0).
elite_mod(unstoppable, stun_immune, 1.0).

evt_mod(blood_moon, [mob_hp(1.5), mob_str(1.5), dark_dmg(10)]).
evt_mod(mana_storm, [mp_cost(0), magic_dmg(2.0), random_teleports(true)]).
evt_mod(wild_hunt, [mob_speed(2.0), player_stealth(-50)]).
evt_mod(plague_winds, [poison_dmg(5), hp_regen_mult(0.1)]).
evt_mod(divine_intervention, [holy_dmg(20), heal_mult(3.0), undead_dmg(2.0)]).
evt_mod(gilded_age, [gold_drop(3.0), shop_cost(0.5)]).
evt_mod(void_rift, [void_dmg(15), mob_tier_up(true)]).
evt_mod(eternal_winter, [ice_dmg(10), move_cost(2)]).
evt_mod(volcanic_eruption, [fire_dmg(10), random_burn(true)]).
evt_mod(thieves_guild, [steal_chance(2.0), player_gold_drain(true)]).
