:- module(config, [
    dmg/2, cost/2, slot/2, weight/2, desc/2,
    consumable/2, val/2, rarity/2, inflicts/4,
    enemy/2, req/3, scale/3, growth/3, mob_xp/2,
    loot_table/5, armor_val/2, cooldown/2,
    race_bonus/3, race_prop/2, restricted_race/1,
    special_player/1, spell_nature/2, req_race/2,
    base_ceiling/3, aggression/2, habitat/2
]).

dmg(fists, 3).
dmg(staff, 5).
dmg(sword, 10).
dmg(fireball, 12).
dmg(iceblast, 8).
dmg(bash, 5).
dmg(poison_dagger, 6).
dmg(mend, 15).
dmg(rejuvenate, 10).
dmg(meteor_storm, 50).
dmg(judgment, 40).

cost(fireball, 5).
cost(iceblast, 6).
cost(bash, 3).
cost(mend, 4).
cost(rejuvenate, 8).
cost(raise_dead, 10).
cost(haste, 5).
cost(stoneskin, 6).
cost(meteor_storm, 25).
cost(judgment, 20).

slot(sword, wpn).
slot(poison_dagger, wpn).
slot(staff, wpn).
slot(shield, shield).
slot(robe, body).

weight(gold, 0).
weight(fists, 0).
weight(sword, 4).
weight(poison_dagger, 2).
weight(staff, 2).
weight(shield, 5).
weight(robe, 2).
weight(potion, 1).
weight(str_potion, 1).

desc(potion, "A bubbling red liquid.").
desc(sword, "A standard iron blade.").

consumable(potion, heal(15)).
consumable(str_potion, buff(str, 5, 10)).

val(potion, 10).
val(str_potion, 25).
val(sword, 50).
val(poison_dagger, 150).
val(robe, 20).

rarity(gold, 0).
rarity(potion, 1).
rarity(sword, 2).
rarity(poison_dagger, 4).
rarity(_, 1).

inflicts(fireball, burn, 3, 5).
inflicts(iceblast, freeze, 2, 0).
inflicts(bash, stun, 1, 0).
inflicts(poison_dagger, poison, 4, 3).
inflicts(rejuvenate, regen, 3, 0).
inflicts(haste, haste, 3, 25).
inflicts(stoneskin, buff, 5, 5).
inflicts(meteor_storm, burn, 5, 10).
inflicts(judgment, stun, 1, 0).

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
scale(_, str, 1.0).

growth(fighter, str, 3).
growth(fighter, dex, 2).
growth(fighter, int, 1).
growth(wizard, str, 1).
growth(wizard, dex, 2).
growth(wizard, int, 3).

mob_xp(goblin, 120).
mob_xp(wolf, 150).
mob_xp(basilisk, 400).
mob_xp(phoenix, 600).
mob_xp(shadow_panther, 300).
mob_xp(_, 100).

loot_table(goblin, gold, 1.0, 5, 20).
loot_table(goblin, potion, 0.4, 1, 2).
loot_table(goblin, sword, 0.05, 1, 1).

armor_val(robe, 2).
armor_val(shield, 5).
armor_val(_, 0).

cooldown(fireball, 3).
cooldown(iceblast, 4).
cooldown(bash, 2).
cooldown(mend, 2).
cooldown(rejuvenate, 4).
cooldown(raise_dead, 8).
cooldown(haste, 6).
cooldown(stoneskin, 6).
cooldown(meteor_storm, 10).
cooldown(judgment, 8).

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

spell_nature(fireball, damage).
spell_nature(iceblast, damage).
spell_nature(mend, healing).
spell_nature(rejuvenate, healing).
spell_nature(raise_dead, necromancy).
spell_nature(haste, buff).
spell_nature(stoneskin, buff).
spell_nature(meteor_storm, cataclysm).
spell_nature(judgment, cataclysm).

req_race(meteor_storm, demigod).
req_race(judgment, angel).

base_ceiling(fighter, str, 40).
base_ceiling(fighter, dex, 35).
base_ceiling(fighter, int, 20).
base_ceiling(wizard, str, 20).
base_ceiling(wizard, dex, 30).
base_ceiling(wizard, int, 45).

aggression(dog, neutral).
aggression(wolf, aggressive).
aggression(basilisk, aggressive).
aggression(phoenix, neutral).
aggression(shadow_panther, aggressive).
aggression(_, aggressive).

habitat(dog, settlement).
habitat(dog, forest).
habitat(wolf, forest).
habitat(basilisk, cave).
habitat(basilisk, swamp).
habitat(phoenix, volcano).
habitat(shadow_panther, cave).
habitat(_, _).
