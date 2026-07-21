:- module(config, [
    dmg/2, cost/2, slot/2, weight/2, desc/2,
    consumable/2, val/2, rarity/2, inflicts/4,
    enemy/2, req/3, scale/3, growth/3, mob_xp/2,
    loot_table/5, armor_val/2, cooldown/2
]).

dmg(fists, 3).
dmg(staff, 5).
dmg(sword, 10).
dmg(fireball, 12).
dmg(iceblast, 8).
dmg(bash, 5).
dmg(poison_dagger, 6).

cost(fireball, 5).
cost(iceblast, 6).
cost(bash, 3).

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

enemy(guard, monster).
enemy(guard, criminal).
enemy(citizen, monster).
enemy(citizen, criminal).
enemy(player, monster).

req(sword, str, 10).
req(staff, int, 10).
req(fireball, int, 15).
req(_, _, 0).

scale(sword, str, 1.2).
scale(poison_dagger, dex, 1.5).
scale(fists, str, 1.0).
scale(staff, int, 1.2).
scale(fireball, int, 1.5).
scale(_, str, 1.0).

growth(fighter, str, 3).
growth(fighter, dex, 2).
growth(fighter, int, 1).
growth(wizard, str, 1).
growth(wizard, dex, 2).
growth(wizard, int, 3).

mob_xp(goblin, 120).
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
