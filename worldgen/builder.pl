:- module(builder, [build_starter_world/0]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('dungeon').
:- use_module(library(random)).
:- use_module(library(lists)).

build_starter_world :-
    world:clear_db,
    seed_hub,
    generate_and_merge(mine, 3, 6, mine_entrance),
    generate_and_merge(forest, 3, 8, forest_trail),
    generate_and_merge(crypt, 10, 8, graveyard),
    generate_and_merge(volcano, 25, 10, mountain_trail),
    seed_citizens.

init_hub_room(R, NR) :-
    get_dict(theme, R, Theme),
    world_config:theme_env_base(Theme, BTemp, BMag, BCor),
    random_between(-5, 5, TOff), random_between(-5, 5, MOff), random_between(-5, 5, COff),
    Temp is BTemp + TOff, Mag is max(0, BMag + MOff), Cor is max(0, BCor + COff),
    NR = R.put(env, dict{temp: Temp, magic: Mag, corr: Cor}).

seed_hub :-
    Rooms = [
        dict{
            id: square,
            theme: village,
            type: outdoor,
            desc: "The central town square. A cool mountain river rushes past a stone fountain here.",
            exits: dict{north: tavern, south: temple, east: barracks, west: mine_entrance, forest: forest_trail, farm: farm_field, mountain: mountain_trail, wild: 'cell_0_0_0'},
            props: [safe, landmark, square, river],
            region: shire
        },
        dict{
            id: tavern,
            theme: village,
            type: indoor,
            desc: "The Rusty Flagon. A rowdy tavern complete with comfortable beds, heavy oak chairs, and a baking oven.",
            exits: dict{south: square, upstairs: tavern_loft},
            props: [safe, oven, tavern],
            furniture: dict{
                stool_1: dict{type: chair, user: none},
                stool_2: dict{type: chair, user: none}
            },
            region: shire
        },
        dict{
            id: tavern_loft,
            theme: village,
            type: indoor,
            desc: "The quiet upper floor of the tavern. Soft straw beds line the walls under a wooden ceiling.",
            exits: dict{downstairs: tavern},
            props: [safe, bed],
            region: shire
        },
        dict{
            id: temple,
            theme: monastery,
            type: indoor,
            desc: "Sanctuary of Light. A grand cathedral housing the resplendent Altar of Sol. The air is thick with holy incense.",
            exits: dict{crypt: graveyard, north: square},
            props: [safe, altar_of_sol, ritual_circle],
            region: shire
        },
        dict{
            id: barracks,
            theme: keep,
            type: indoor,
            desc: "The town guard barracks. Weapon racks, shield braces, and training dummies line the stone walls.",
            exits: dict{west: square, south: prison, tower: watchtower},
            props: [safe, training_dummy],
            breakables: dict{
                rack_1: dict{type: crate, hp: 20}
            },
            region: shire
        },
        dict{
            id: watchtower,
            theme: keep,
            type: outdoor,
            desc: "The high watchtower overlooking the shire. Banners flutter loudly in the strong wind.",
            exits: dict{down: barracks},
            props: [safe, windy],
            region: shire
        },
        dict{
            id: prison,
            theme: prison,
            type: indoor,
            desc: "The iron-barred dungeon. It is bleak, secure, and inescapable. Clangs of chains echo through the cells.",
            exits: dict{north: barracks},
            props: [prison, dark],
            region: shire
        },
        dict{
            id: farm_field,
            theme: plains,
            type: outdoor,
            desc: "A tilled farming field. Fertile soil stretches out in neat furrows under the open sky.",
            exits: dict{east: orchard, south: windmill, town: square},
            props: [safe, tilled],
            region: shire
        },
        dict{
            id: orchard,
            theme: grove,
            type: outdoor,
            desc: "A dense apple orchard. Sweet-smelling blossoms hang low from thick, sturdy branches.",
            exits: dict{west: farm_field},
            props: [safe],
            nodes: dict{
                apple_tree: dict{tag: oak_tree, qty: 5}
            },
            region: shire
        },
        dict{
            id: windmill,
            theme: village,
            type: indoor,
            desc: "A towering wooden windmill. Large stone gears creak endlessly as they grind wheat into flour.",
            exits: dict{north: farm_field},
            props: [safe],
            region: shire
        },
        dict{
            id: mine_entrance, theme: mine, type: normal,
            desc: "The dark, excavated entrance to an abandoned mine.",
            exits: dict{east: square}, props: []
        },
        dict{
            id: forest_trail, theme: forest, type: normal,
            desc: "A sprawling ancient canopy marking the edge of the woods.",
            exits: dict{town: square}, props: []
        },
        dict{
            id: graveyard, theme: crypt, type: normal,
            desc: "A dusty catacomb beneath the temple.",
            exits: dict{up: temple}, props: []
        },
        dict{
            id: mountain_trail, theme: volcano, type: normal,
            desc: "A steep and magmatic trail ascending into the clouds.",
            exits: dict{town: square}, props: []
        }
    ],
    maplist(init_hub_room, Rooms, FinalRooms),
    forall(member(R, FinalRooms), world:put_room(R)).

generate_and_merge(Theme, Lvl, Size, EntryId) :-
    dungeon:gen_dun(Theme, Lvl, Size, EntryId, Dun),
    forall(member(R, Dun.rooms), assert_room(R, Lvl)),
    forall(member(M, Dun.mobs), world:put_entity(M)),
    forall(member(I, Dun.items), world:put_entity(I)).

assert_room(R, _Lvl) :-
    world:get_room(R.id, Existing), !,
    get_dict(exits, Existing, Ex1),
    get_dict(exits, R, Ex2),
    NExits = Ex1.put(Ex2),
    NR = Existing.put(exits, NExits),
    world:put_room(NR).
assert_room(R, Lvl) :-
    roll_resource_nodes(R, Lvl, NR),
    world:put_room(NR).

roll_resource_nodes(R, Lvl, NR) :-
    get_dict(theme, R, Theme),
    random_between(1, 100, Roll),
    ( Roll =< 40, theme_node(Theme, Lvl, Tag) ->
        random_between(3, 8, Qty),
        random_between(100000, 999999, Rnd),
        atomic_list_concat([node_, Tag, '_', Rnd], NodeId),
        ( get_dict(nodes, R, Nodes) ->
            NNodes = Nodes.put(NodeId, dict{tag: Tag, qty: Qty})
        ;
            NNodes = dict{}.put(NodeId, dict{tag: Tag, qty: Qty})
        ),
        NR = R.put(nodes, NNodes)
    ;
        NR = R
    ).

theme_node(mine, Lvl, iron_vein) :- Lvl < 5, !.
theme_node(mine, Lvl, silver_vein) :- Lvl >= 5, Lvl < 15, !.
theme_node(mine, _, gold_vein).
theme_node(cavern, _, coal_vein).
theme_node(forest, _, oak_tree).
theme_node(grove, _, herb_patch).
theme_node(swamp, _, mushroom_patch).
theme_node(volcano, _, basalt_fissure).

seed_citizens :-
    Mobs = [
        mob{
          id: guard_nycolas, tag: guard, name: "Guard Nycolas", lvl: 40,
          hp: 300, max_hp: 300, mp: 30, max_mp: 30,
          str: 50, dex: 45, con: 50, int: 25, wis: 25, cha: 35, luk: 20,
          room: square, fac: guard, props: [protector],
          equip: dict{wpn: iron_sword, shield: iron_shield, body: chainmail},
          route: [square, barracks, prison], route_idx: 0, wander: false,
          threats: dict{}, mems: dict{}
        },
        mob{
            id: guard_sam, tag: guard, name: "Captain Sam", lvl: 10,
            hp: 150, max_hp: 150, mp: 30, max_mp: 30,
            str: 25, dex: 20, con: 25, int: 12, wis: 15, cha: 15, luk: 12,
            room: square, fac: guard, props: [protector],
            equip: dict{wpn: iron_sword, shield: iron_shield, body: chainmail},
            route: [square, barracks, prison], route_idx: 0, wander: false,
            threats: dict{}, mems: dict{}
        },
        mob{
            id: peasant_bob, tag: peasant, name: "Bob the Farmer", lvl: 1,
            hp: 30, max_hp: 30, mp: 10, max_mp: 10,
            str: 12, dex: 10, con: 14, int: 8, wis: 10, cha: 10, luk: 12,
            room: square, fac: citizen, job: peasant, home: tavern, work: farm_field,
            act_state: wander, props: [], equip: dict{wpn: fists, shield: none, body: tunic},
            wander: true, inv: [stack{tag: wheat_seed, qty: 3}, stack{tag: bread, qty: 2}],
            threats: dict{}, mems: dict{}
        },
        mob{
            id: merchant_silvia, tag: merchant, name: "Silvia the Merchant", lvl: 5,
            hp: 60, max_hp: 60, mp: 40, max_mp: 40,
            str: 10, dex: 12, con: 12, int: 14, wis: 15, cha: 18, luk: 15,
            room: square, fac: merchant, job: merchant, home: tavern, work: square,
            act_state: wander, props: [merchant], equip: dict{wpn: dagger, shield: none, body: tunic},
            wander: false, inv: [
                stack{tag: gold, qty: 500}, stack{tag: diviners_orb, qty: 1}, stack{tag: bread, qty: 10}, stack{tag: apple, qty: 10},
                stack{tag: empty_waterskin, qty: 5}, stack{tag: flint_and_steel, qty: 2}, stack{tag: whetstone, qty: 2}
            ],
            threats: dict{}, mems: dict{}
        },
        mob{
            id: priest_luke, tag: priest, name: "Father Luke", lvl: 8,
            hp: 80, max_hp: 80, mp: 80, max_mp: 80,
            str: 10, dex: 10, con: 12, int: 16, wis: 20, cha: 15, luk: 12,
            room: temple, fac: citizen, job: citizen, home: temple, work: temple,
            act_state: wander, props: [healer], equip: dict{wpn: staff, shield: none, body: tunic},
            wander: false, inv: [stack{tag: gold, qty: 100}, stack{tag: holy_water, qty: 5}],
            threats: dict{}, mems: dict{}
        }
    ],
    forall(member(M, Mobs), world:put_entity(M)),

    Items = [
        item{id: floor_hoe, tag: hoe, qty: 1, room: square},
        item{id: floor_pole, tag: fishing_pole, qty: 1, room: square},
        item{id: floor_flint, tag: flint_and_steel, qty: 1, room: square},
        item{id: floor_skin, tag: empty_waterskin, qty: 1, room: square}
    ],
    forall(member(I, Items), world:put_entity(I)).
