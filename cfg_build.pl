:- module(cfg_build, [struct_data/4]).
struct_data(wooden_wall, [stack{tag: timber, qty: 5}], obstacle, wall).
struct_data(wooden_door, [stack{tag: timber, qty: 3}], door, door).
struct_data(wooden_chest, [stack{tag: timber, qty: 5}], container, chest).
struct_data(campfire, [stack{tag: timber, qty: 2}], prop, campfire(30)).
