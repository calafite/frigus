:- module(cfg_item, [
    dmg/2, slot/2, weight/2, desc/2,
    consumable/2, val/2, rarity/2,
    armor_val/2, soulbound/1
]).

dmg(wooden_sword, 5).
dmg(_, 1).

slot(Tag, wpn) :- member(Tag, [sword, dagger, greatsword, battleaxe, longbow, magic_wand, wooden_club, bronze_dagger, bronze_sword, iron_mace, iron_spear, steel_claymore, steel_halberd, composite_bow, excalibur, shadowfang, gungnir, mjolnir, solaris, staff]).
slot(Tag, shield) :- member(Tag, [wooden_shield, iron_shield, steel_shield, tower_shield, aegis]).
slot(Tag, body) :- member(Tag, [rags, tunic, gambeson, leather_vest, leather_armor, studded_leather, brigandine, chainmail, scale_mail, half_plate, plate_mail, robes]).
slot(_, none).

weight(gold, 0.01).
weight(_, 1.0).

desc(_, "A simple item.").

consumable(health_potion, heal(50)).
val(gold, 1).
val(_, 10).
rarity(_, 1).

armor_val(rags, 1). armor_val(leather_armor, 5). armor_val(chainmail, 10). armor_val(plate_mail, 20).
armor_val(_, 0).
soulbound(excalibur).
