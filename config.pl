:- module(config, [
    dmg/2, cost/2, slot/2,
    weight/2, desc/2,
    consumable/2, val/2,
    enemy/2, req/3, scale/3,
    growth/3, mob_xp/2
]).

dmg(fists, 3).
dmg(staff, 5).
dmg(sword, 10).
dmg(fireball, 12).

cost(fireball, 5).

slot(sword, wpn).
slot(staff, wpn).
slot(shield, shield).
slot(robe, body).

weight(gold, 0).
weight(fists, 0).
weight(sword, 4).
weight(staff, 2).
weight(shield, 5).
weight(robe, 2).
weight(potion, 1).

desc(potion, "A bubbling red liquid.").
desc(sword, "A standard iron blade.").

consumable(potion, heal(15)).

val(potion, 10).
val(sword, 50).
val(robe, 20).

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
