:- module(cfg_combat, [
    dmg/2,
    inflicts/4,
    enemy/2,
    req/3,
    scale/3
]).

dmg(fists, 3).
dmg(staff, 5).
dmg(sword, 10).
dmg(dagger, 5).
dmg(greatsword, 18).
dmg(battleaxe, 14).
dmg(longbow, 11).
dmg(magic_wand, 4).
dmg(wooden_club, 4).
dmg(bronze_dagger, 5).
dmg(bronze_sword, 7).
dmg(iron_mace, 10).
dmg(iron_spear, 9).
dmg(steel_claymore, 15).
dmg(steel_halberd, 16).
dmg(composite_bow, 12).
dmg(excalibur, 25).
dmg(shadowfang, 20).
dmg(gungnir, 24).
dmg(mjolnir, 40).
dmg(solaris, 35).
dmg(fireball, 12).
dmg(iceblast, 8).
dmg(bash, 5).
dmg(poison_dagger, 6).
dmg(mend, 15).
dmg(rejuvenate, 10).
dmg(meteor_storm, 50).
dmg(judgment, 40).
dmg(fireblast, 22).
dmg(holy_light, 20).
dmg(earthquake, 35).
dmg(chain_lightning, 16).

inflicts(fireball, burn, 3, 5).
inflicts(iceblast, freeze, 2, 0).
inflicts(bash, stun, 1, 0).
inflicts(poison_dagger, poison, 4, 3).
inflicts(rejuvenate, regen, 3, 0).
inflicts(haste, haste, 3, 25).
inflicts(stoneskin, buff, 5, 5).
inflicts(meteor_storm, burn, 5, 10).
inflicts(judgment, stun, 1, 0).
inflicts(fireblast, burn, 4, 8).
inflicts(earthquake, stun, 2, 0).
inflicts(chain_lightning, stun, 1, 0).
inflicts(giant_spider, poison, 3, 4).
inflicts(snake, poison, 2, 2).
inflicts(shadowfang, poison, 5, 5).
inflicts(mjolnir, stun, 2, 0).
inflicts(solaris, burn, 4, 12).

enemy(guard, monster).
enemy(guard, criminal).
enemy(citizen, monster).
enemy(citizen, criminal).
enemy(player, monster).

req(sword, str, 10).
req(staff, int, 10).
req(fireball, int, 15).
req(mend, int, 10).
req(rejuvenate, int, 12).
req(raise_dead, int, 14).
req(haste, dex, 12).
req(stoneskin, str, 12).
req(meteor_storm, int, 30).
req(judgment, int, 25).
req(greatsword, str, 25).
req(battleaxe, str, 18).
req(longbow, dex, 15).
req(dagger, dex, 8).
req(plate_mail, str, 22).
req(tower_shield, str, 20).
req(leather_armor, dex, 12).
req(fireblast, int, 24).
req(earthquake, int, 28).
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
req(_, _, 0).

scale(sword, str, 1.2).
scale(poison_dagger, dex, 1.5).
scale(fists, str, 1.0).
scale(staff, int, 1.2).
scale(fireball, int, 1.5).
scale(mend, int, 1.0).
scale(rejuvenate, int, 0.5).
scale(meteor_storm, int, 2.0).
scale(judgment, int, 1.5).
scale(dagger, dex, 1.2).
scale(greatsword, str, 1.8).
scale(battleaxe, str, 1.4).
scale(longbow, dex, 1.3).
scale(magic_wand, int, 1.0).
scale(fireblast, int, 1.8).
scale(holy_light, int, 1.2).
scale(earthquake, int, 2.2).
scale(chain_lightning, int, 1.4).
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
scale(mjolnir, str, 3.0).
scale(solaris, int, 3.0).
scale(_, str, 1.0).
