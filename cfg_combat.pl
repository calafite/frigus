:- module(cfg_combat, [
    wpn_dmg/2, ar_pen/2, reach/2,
    inflicts/4, req/3, scale/3,
    weakness/3, resist/3, immune/2,
    shield_block/3, physical_type/1
]).

physical_type(slash).
physical_type(pierce).
physical_type(blunt).

wpn_dmg(fists, [dmg(blunt, 3)]).
wpn_dmg(staff, [dmg(blunt, 5)]).
wpn_dmg(sword, [dmg(slash, 8), dmg(pierce, 2)]).
wpn_dmg(dagger, [dmg(pierce, 5)]).
wpn_dmg(greatsword, [dmg(slash, 18)]).
wpn_dmg(battleaxe, [dmg(slash, 14)]).
wpn_dmg(longbow, [dmg(pierce, 11)]).
wpn_dmg(magic_wand, [dmg(magic, 4)]).
wpn_dmg(wooden_club, [dmg(blunt, 4)]).
wpn_dmg(bronze_dagger, [dmg(pierce, 5)]).
wpn_dmg(bronze_sword, [dmg(slash, 6), dmg(pierce, 1)]).
wpn_dmg(iron_mace, [dmg(blunt, 10)]).
wpn_dmg(iron_spear, [dmg(pierce, 9)]).
wpn_dmg(steel_claymore, [dmg(slash, 15)]).
wpn_dmg(steel_halberd, [dmg(slash, 12), dmg(pierce, 4)]).
wpn_dmg(composite_bow, [dmg(pierce, 12)]).
wpn_dmg(excalibur, [dmg(slash, 15), dmg(holy, 10)]).
wpn_dmg(shadowfang, [dmg(pierce, 10), dmg(dark, 10)]).
wpn_dmg(gungnir, [dmg(pierce, 14), dmg(lightning, 10)]).
wpn_dmg(mjolnir, [dmg(blunt, 20), dmg(lightning, 20)]).
wpn_dmg(solaris, [dmg(slash, 15), dmg(fire, 20)]).

wpn_dmg(fireball, [dmg(fire, 12)]).
wpn_dmg(iceblast, [dmg(ice, 8)]).
wpn_dmg(bash, [dmg(blunt, 5)]).
wpn_dmg(poison_dagger, [dmg(pierce, 4), dmg(poison, 2)]).
wpn_dmg(mend, [dmg(holy, 0)]).
wpn_dmg(rejuvenate, [dmg(nature, 0)]).
wpn_dmg(meteor_storm, [dmg(fire, 30), dmg(blunt, 20)]).
wpn_dmg(judgment, [dmg(holy, 40)]).
wpn_dmg(fireblast, [dmg(fire, 22)]).
wpn_dmg(holy_light, [dmg(holy, 20)]).
wpn_dmg(earthquake, [dmg(blunt, 35)]).
wpn_dmg(chain_lightning, [dmg(lightning, 16)]).
wpn_dmg(bloodline_curse, [dmg(dark, 15)]).

wpn_dmg(wolf, [dmg(slash, 4), dmg(pierce, 2)]).
wpn_dmg(bear, [dmg(slash, 8), dmg(blunt, 4)]).
wpn_dmg(giant_spider, [dmg(pierce, 4), dmg(poison, 4)]).
wpn_dmg(shadow_panther, [dmg(slash, 8), dmg(dark, 4)]).
wpn_dmg(griffin, [dmg(slash, 10), dmg(pierce, 6)]).
wpn_dmg(dragon, [dmg(slash, 20), dmg(fire, 20)]).
wpn_dmg(skeleton, [dmg(blunt, 4), dmg(slash, 2)]).
wpn_dmg(zombie, [dmg(blunt, 6)]).
wpn_dmg(wraith, [dmg(dark, 10), dmg(ice, 4)]).
wpn_dmg(vampire, [dmg(pierce, 8), dmg(dark, 8)]).
wpn_dmg(demon, [dmg(slash, 12), dmg(fire, 8)]).
wpn_dmg(imp, [dmg(pierce, 3), dmg(fire, 3)]).
wpn_dmg(golem, [dmg(blunt, 15)]).
wpn_dmg(slime, [dmg(blunt, 2), dmg(poison, 2)]).
wpn_dmg(basilisk, [dmg(pierce, 8), dmg(poison, 8)]).

ar_pen(iron_mace, 0.3).
ar_pen(mjolnir, 0.5).
ar_pen(dagger, 0.2).
ar_pen(bronze_dagger, 0.2).
ar_pen(shadowfang, 0.4).
ar_pen(steel_halberd, 0.2).
ar_pen(greatsword, 0.1).
ar_pen(battleaxe, 0.1).
ar_pen(wooden_club, 0.1).
ar_pen(_, 0.0).

reach(longbow, 10).
reach(composite_bow, 12).
reach(shortbow, 8).
reach(crossbow, 10).
reach(iron_spear, 2).
reach(steel_halberd, 2).
reach(pike, 3).
reach(glaive, 2).
reach(gungnir, 3).
reach(magic_wand, 5).
reach(staff, 2).
reach(fireball, 15).
reach(iceblast, 10).
reach(meteor_storm, 20).
reach(chain_lightning, 15).
reach(fireblast, 12).
reach(bloodline_curse, 15).
reach(holy_light, 15).
reach(_, 1).

shield_block(wooden_shield, 15, 5).
shield_block(iron_shield, 20, 10).
shield_block(steel_shield, 25, 15).
shield_block(tower_shield, 35, 25).
shield_block(aegis, 40, 40).
shield_block(_, 0, 0).

weakness(skeleton, blunt, 2.0).
weakness(skeleton, holy, 2.0).
weakness(zombie, fire, 1.5).
weakness(zombie, slash, 1.5).
weakness(zombie, holy, 2.0).
weakness(wraith, holy, 2.0).
weakness(wraith, magic, 1.5).
weakness(vampire, holy, 2.0).
weakness(vampire, fire, 1.5).
weakness(demon, holy, 2.0).
weakness(demon, ice, 1.5).
weakness(imp, holy, 1.5).
weakness(imp, ice, 1.5).
weakness(golem, blunt, 1.5).
weakness(golem, magic, 1.5).
weakness(slime, fire, 2.0).
weakness(slime, ice, 2.0).
weakness(giant_spider, fire, 1.5).
weakness(ent, fire, 2.0).
weakness(dryad, fire, 1.5).
weakness(dryad, dark, 1.5).
weakness(angel, dark, 2.0).
weakness(angel, void, 1.5).
weakness(ice_wolf, fire, 2.0).
weakness(_, _, 1.0).

resist(skeleton, pierce, 0.5).
resist(skeleton, poison, 0.0).
resist(zombie, blunt, 0.5).
resist(zombie, poison, 0.0).
resist(wraith, phys, 0.1).
resist(wraith, poison, 0.0).
resist(vampire, dark, 0.5).
resist(vampire, poison, 0.5).
resist(demon, fire, 0.2).
resist(demon, dark, 0.5).
resist(imp, fire, 0.0).
resist(golem, slash, 0.2).
resist(golem, pierce, 0.2).
resist(golem, poison, 0.0).
resist(slime, phys, 0.5).
resist(slime, poison, 0.0).
resist(dragon, fire, 0.1).
resist(dragon, magic, 0.5).
resist(shadow_panther, dark, 0.2).
resist(angel, holy, 0.0).
resist(ice_wolf, ice, 0.0).
resist(_, _, 1.0).

immune(skeleton, poison).
immune(zombie, poison).
immune(wraith, poison).
immune(golem, poison).
immune(slime, poison).
immune(demon, fire).
immune(imp, fire).
immune(dragon, fire).
immune(angel, holy).
immune(ice_wolf, ice).
immune(fire_sprite, fire).
immune(salamander, fire).
immune(_, none).

inflicts(poison_dagger, poison, 4, 3).
inflicts(haste, haste, 3, 25).
inflicts(stoneskin, buff, 5, 5).
inflicts(meteor_storm, burn, 5, 10).
inflicts(fireblast, burn, 4, 8).
inflicts(giant_spider, poison, 3, 4).
inflicts(snake, poison, 2, 2).
inflicts(shadowfang, poison, 5, 5).
inflicts(solaris, burn, 4, 12).
inflicts(bloodline_curse, bloodline_curse, 10, 8).
inflicts(_, none, 0, 0).

req(sword, str, 10).
req(staff, int, 10).
req(fireball, int, 15).
req(mend, wis, 10).
req(rejuvenate, wis, 12).
req(meteor_storm, int, 30).
req(judgment, wis, 25).
req(greatsword, str, 25).
req(battleaxe, str, 18).
req(longbow, dex, 15).
req(dagger, dex, 8).
req(plate_mail, con, 22).
req(tower_shield, con, 20).
req(leather_armor, dex, 12).
req(fireblast, int, 24).
req(earthquake, wis, 28).
req(chain_lightning, int, 18).
req(wooden_club, str, 8).
req(bronze_dagger, dex, 8).
req(bronze_sword, str, 10).
req(iron_mace, str, 12).
req(iron_spear, dex, 10).
req(steel_claymore, str, 18).
req(steel_halberd, str, 16).
req(composite_bow, dex, 14).
req(excalibur, str, 25).
req(shadowfang, dex, 25).
req(gungnir, dex, 24).
req(mjolnir, str, 40).
req(solaris, int, 40).
req(bloodline_curse, cha, 35).
req(_, _, 0).

scale(sword, str, 1.2).
scale(poison_dagger, dex, 1.5).
scale(fists, str, 1.0).
scale(staff, int, 1.2).
scale(fireball, int, 1.5).
scale(mend, wis, 1.5).
scale(rejuvenate, wis, 1.2).
scale(meteor_storm, int, 2.0).
scale(judgment, wis, 1.8).
scale(dagger, dex, 1.2).
scale(greatsword, str, 1.8).
scale(battleaxe, str, 1.6).
scale(longbow, dex, 1.5).
scale(magic_wand, int, 1.2).
scale(fireblast, int, 1.8).
scale(holy_light, wis, 1.5).
scale(earthquake, wis, 2.2).
scale(chain_lightning, int, 1.6).
scale(wooden_club, str, 1.0).
scale(bronze_dagger, dex, 1.1).
scale(bronze_sword, str, 1.1).
scale(iron_mace, str, 1.2).
scale(iron_spear, dex, 1.2).
scale(steel_claymore, str, 1.5).
scale(steel_halberd, str, 1.4).
scale(composite_bow, dex, 1.4).
scale(excalibur, str, 2.0).
scale(shadowfang, dex, 2.2).
scale(gungnir, dex, 2.0).
scale(mjolnir, str, 2.5).
scale(solaris, int, 2.5).
scale(bloodline_curse, cha, 2.5).
scale(_, str, 1.0).
