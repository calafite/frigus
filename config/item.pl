:- module(item_config, [slot/2, weight/2, val/2, consumable/2]).

% Equipment Slots
slot(sword, wpn).
slot(iron_sword, wpn).
slot(dagger, wpn).
slot(staff, wpn).
slot(fists, wpn).
slot(shortbow, wpn).
slot(greatsword, wpn).
slot(battleaxe, wpn).
slot(ancient_runesword, wpn).
slot(vampire_fanged_blade, wpn).
slot(necromancer_staff, wpn).
slot(seraphs_blade, wpn).

slot(iron_shield, shield).
slot(wooden_shield, shield).
slot(living_bark_shield, shield).

slot(chainmail, body).
slot(tunic, body).
slot(rags, body).
slot(dragon_scale_mail, body).
slot(void_robe, body).
slot(_, none).

weight(gold, 0.01).
weight(_, 1.0).

% Item Values
val(gold, 1).
val(sword, 15).
val(health_potion, 20).
val(diviners_orb, 1200). % High-value ancient artifact
val(dragon_heart, 300).
val(witch_brew, 150).
val(ancient_core, 250).
val(blood_ruby, 400).
val(astral_shard, 200).
val(treant_heartwood, 180).
val(vampire_fanged_blade, 500).
val(dragon_scale_mail, 750).
val(ancient_runesword, 600).
val(necromancer_staff, 550).
val(seraphs_blade, 1000).
val(_, 10).

% Consumable Item Effects
consumable(health_potion, heal(50)).
consumable(mana_potion, restore_mp(50)).
consumable(apple, heal(10)).
consumable(bread, heal(15)).
consumable(dragon_heart, heal(250)).
consumable(treant_heartwood, heal(150)).
consumable(witch_brew, restore_mp(150)).
consumable(astral_shard, restore_mp(200)).
consumable(diviners_orb, locate_anomaly).
