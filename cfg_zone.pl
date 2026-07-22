:- module(cfg_zone, [
    terrain_fatigue/2,
    region_of/2,
    breakable_data/3
]).

terrain_fatigue(stone, 1).
terrain_fatigue(grass, 1).
terrain_fatigue(wood, 1).
terrain_fatigue(sand, 2).
terrain_fatigue(shallow_water, 3).
terrain_fatigue(mud, 4).
terrain_fatigue(snow, 3).
terrain_fatigue(ice, 3).
terrain_fatigue(hot_ash, 3).
terrain_fatigue(rubble, 3).

region_of(shire, westland).
region_of(bree, westland).
region_of(rivendell, elfland).
region_of(mordor, wasteland).
region_of(gondor, southland).

breakable_data(crate, [stack{tag: potion, qty: 1}, stack{tag: gold, qty: 10}], 50).
breakable_data(barrel, [stack{tag: empty_waterskin, qty: 1}, stack{tag: gold, qty: 5}], 30).
breakable_data(chest, [stack{tag: excalibur, qty: 1}], 200).
breakable_data(door, [], 100).
