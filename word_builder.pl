:- module(world_builder, [build_starter_world/0]).

:- use_module(world).
:- use_module(proc_dungeon).
:- use_module(library(random)).
:- use_module(library(lists)).

build_starter_world :-
    world:clear_db,
    seed_hub,
    generate_and_merge(mine, 3, 6, mine_entrance),
    generate_and_merge(forest, 3, 8, forest_trail),
    generate_and_merge(crypt, 10, 8, graveyard),
    generate_and_merge(volcano, 25, 10, mountain_trail),
    seed_citizens,
    seed_world_state.

seed_hub :-
    Rooms = [
        dict{
            id: square,
            theme: village,
            type: outdoor,
            desc: "The central town square. A cool mountain river rushes past a stone fountain here.",
            exits: dict{north: tavern, south: temple, east: barracks, west: mine_entrance, forest: forest_trail, farm: farm_field, wild: cell(0, 0, 0)},
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
            exits: dict{north: square, crypt: graveyard},
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
            desc: "The iron-barred dungeon. It is bleak, secure, and inescapable. Clings of chains echo through the cells.",
            exits: dict{north: barracks},
            props: [prison, dark],
            region: shire
        },
        dict{
            id: farm_field,
            theme: plains,
            type: outdoor,
            desc: "A tilled farming field. Fertile soil stretches out in neat furrows under the open sky.",
            exits: dict{square: square, east: orchard, south: windmill},
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
        }
    ],
    forall(member(R, Rooms), assertz(world:db_node(R.id, R))).

generate_and_merge(Theme, Lvl, Size, EntryId) :-
    proc_dungeon:gen_dun(Theme, Lvl, Size, EntryId, Dun),
    merge_dungeon(Dun, Lvl).

merge_dungeon(Dun, Lvl) :-
    forall(member(R, Dun.rooms), assert_room(R, Lvl)),
    forall(member(M, Dun.mobs), assertz(world:db_entity(mob, M.id, M))),
    forall(member(I, Dun.items), assertz(world:db_entity(item, I.id, I))).

assert_room(R, Lvl) :-
    world:db_node(R.id, Existing), !,
    get_dict(exits, Existing, Ex1),
    get_dict(exits, R, Ex2),
    dict_pairs(Ex1, _, P1),
    dict_pairs(Ex2, _, P2),
    append(P1, P2, PAll),
    list_to_set(PAll, USet),
    dict_pairs(NExits, _, USet),
    NR = Existing.put(exits, NExits),
    retractall(world:db_node(R.id, _)),
    assertz(world:db_node(R.id, NR)).

assert_room(R, Lvl) :-
    roll_resource_nodes(R, Lvl, NR),
    assertz(world:db_node(R.id, NR)).

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
        dict{
            id: guard_sam,
            tag: guard,
            name: "Captain Sam",
            lvl: 10,
            hp: 150, max_hp: 150, mp: 30, max_mp: 30,
            str: 25, dex: 20, con: 25, int: 12, wis: 15, cha: 15, luk: 12,
            room: square,
            fac: guard,
            props: [protector],
            equip: dict{wpn: iron_sword, shield: iron_shield, body: chainmail},
            route: [square, barracks, prison],
            route_idx: 0,
            wander: false,
            threats: dict{},
            mems: dict{}
        },
        dict{
            id: guard_jerry,
            tag: guard,
            name: "Guard Jerry",
            lvl: 8,
            hp: 120, max_hp: 120, mp: 20, max_mp: 20,
            str: 20, dex: 18, con: 20, int: 10, wis: 12, cha: 12, luk: 10,
            room: square,
            fac: guard,
            props: [protector],
            equip: dict{wpn: iron_spear, shield: wooden_shield, body: studded_leather},
            route: [square, farm_field],
            route_idx: 0,
            wander: false,
            threats: dict{},
            mems: dict{}
        },
        dict{
            id: peasant_bob,
            tag: peasant,
            name: "Bob the Farmer",
            lvl: 1,
            hp: 30, max_hp: 30, mp: 10, max_mp: 10,
            str: 12, dex: 10, con: 14, int: 8, wis: 10, cha: 10, luk: 12,
            room: square,
            fac: citizen,
            job: peasant,
            home: tavern,
            work: farm_field,
            act_state: wander,
            props: [],
            equip: dict{wpn: fists, shield: none, body: tunic},
            wander: true,
            inv: [
                stack{tag: wheat_seed, qty: 3},
                stack{tag: bread, qty: 2}
            ],
            threats: dict{},
            mems: dict{}
        },
        dict{
            id: miner_ted,
            tag: miner,
            name: "Ted the Miner",
            lvl: 2,
            hp: 40, max_hp: 40, mp: 10, max_mp: 10,
            str: 15, dex: 10, con: 16, int: 8, wis: 8, cha: 8, luk: 10,
            room: mine_entrance,
            fac: citizen,
            job: miner,
            home: tavern,
            work: mine_entrance,
            act_state: wander,
            props: [],
            equip: dict{wpn: fists, shield: none, body: rags},
            wander: true,
            inv: [
                stack{tag: pickaxe, qty: 1},
                stack{tag: coal, qty: 3}
            ],
            threats: dict{},
            mems: dict{}
        },
        dict{
            id: merchant_silvia,
            tag: merchant,
            name: "Silvia the Merchant",
            lvl: 5,
            hp: 60, max_hp: 60, mp: 40, max_mp: 40,
            str: 10, dex: 12, con: 12, int: 14, wis: 15, cha: 18, luk: 15,
            room: square,
            fac: merchant,
            job: merchant,
            home: tavern,
            work: square,
            act_state: wander,
            props: [merchant],
            equip: dict{wpn: dagger, shield: none, body: robes},
            wander: false,
            inv: [
                stack{tag: gold, qty: 500},
                stack{tag: bread, qty: 10},
                stack{tag: apple, qty: 10},
                stack{tag: empty_waterskin, qty: 5},
                stack{tag: flint_and_steel, qty: 2},
                stack{tag: whetstone, qty: 2}
            ],
            threats: dict{},
            mems: dict{}
        },
        dict{
            id: priest_luke,
            tag: priest,
            name: "Father Luke",
            lvl: 8,
            hp: 80, max_hp: 80, mp: 80, max_mp: 80,
            str: 10, dex: 10, con: 12, int: 16, wis: 20, cha: 15, luk: 12,
            room: temple,
            fac: citizen,
            job: citizen,
            home: temple,
            work: temple,
            act_state: wander,
            props: [healer],
            equip: dict{wpn: staff, shield: none, body: robes},
            wander: false,
            inv: [
                stack{tag: gold, qty: 100},
                stack{tag: holy_water, qty: 5}
            ],
            threats: dict{},
            mems: dict{}
        }
    ],
    forall(member(M, Mobs), assertz(world:db_entity(mob, M.id, M))),
    Items = [
        dict{id: floor_hoe, tag: hoe, qty: 1, room: square},
        dict{id: floor_pole, tag: fishing_pole, qty: 1, room: square},
        dict{id: floor_flint, tag: flint_and_steel, qty: 1, room: square},
        dict{id: floor_skin, tag: empty_waterskin, qty: 1, room: square}
    ],
    forall(member(I, Items), assertz(world:db_entity(item, I.id, I))).

seed_world_state :-
    retractall(world:db_flag(_, _)),
    assertz(world:db_flag(help_call_room, none)),
    assertz(world:db_flag(help_call_tag, none)),
    assertz(world:db_flag(world_seed, 948123)),
    retractall(env:db_env(_)),
    assertz(env:db_env(env{hr: 12, min: 0, day: 1, mon: 1, seas: spring, weath: clear, moon: new_moon})),
    retractall(social:db_social(_)),
    assertz(social:db_social(social{parties: dict{}, guilds: dict{}, trades: dict{}})).
