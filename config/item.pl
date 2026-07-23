:- module(item_config, [slot/2, weight/2, val/2, consumable/2]).

slot(sword, wpn).
slot(dagger, wpn).
slot(staff, wpn).
slot(fists, wpn).
slot(shortbow, wpn).
slot(iron_shield, shield).
slot(wooden_shield, shield).
slot(chainmail, body).
slot(tunic, body).
slot(rags, body).
slot(_, none).

weight(gold, 0.01).
weight(_, 1.0).

val(gold, 1).
val(sword, 15).
val(health_potion, 20).
val(_, 10).

consumable(health_potion, heal(50)).
consumable(mana_potion, restore_mp(50)).
consumable(apple, heal(10)).
consumable(bread, heal(15)).
