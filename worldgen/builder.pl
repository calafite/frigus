:- module(builder, [build_starter_world/0]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('dungeon').
:- use_module(library(random)).
:- use_module(library(lists)).

build_starter_world :-
    world:clear_db,
    seed_hub,
    % Shire Dungeons
    generate_and_merge(mine, 3, 6, mine_entrance),
    generate_and_merge(forest, 3, 8, forest_trail),
    generate_and_merge(crypt, 10, 8, graveyard),
    generate_and_merge(volcano, 25, 10, mountain_trail),
    % Expansion Dungeons
    generate_and_merge(ruins, 12, 10, ruined_path),
    generate_and_merge(keep, 35, 10, abandoned_keep_gate),
    generate_and_merge(cavern, 15, 12, sunken_cove_entrance),
    generate_and_merge(mine, 20, 15, deep_cavern_entrance),
    generate_and_merge(forest, 25, 12, deep_woods_entrance),
    seed_citizens.

init_hub_room(R, NR) :-
    get_dict(theme, R, Theme),
    world_config:theme_env_base(Theme, BTemp, BMag, BCor),
    random_between(-5, 5, TOff), random_between(-5, 5, MOff), random_between(-5, 5, COff),
    Temp is BTemp + TOff, Mag is max(0, BMag + MOff), Cor is max(0, BCor + COff),
    NR = R.put(env, dict{temp: Temp, magic: Mag, corr: Cor}).

seed_hub :-
    Rooms = [
                % --- THE SHIRE (Starter Town) ---
                dict{
                    id: square, theme: village, type: outdoor,
                    desc: "The central town square. A cool mountain river rushes past a stone fountain here. A large wooden board is covered with posted requests.",
                    exits: dict{north: north_road, south: temple, east: barracks, west: mine_entrance, tavern: tavern, forest: forest_trail, farm: farm_field, mountain: mountain_trail, highway: south_road, wild: 'cell_0_0_0'},
                    props: [safe, landmark, square, river, quest_board], region: shire
            },
                dict{
                    id: tavern, theme: village, type: indoor,
                    desc: "The Rusty Flagon. A rowdy tavern complete with comfortable beds, heavy oak chairs, and a baking oven.",
                    exits: dict{out: square, upstairs: tavern_loft},
                    props: [safe, oven, tavern], furniture: dict{stool_1: dict{type: chair, user: none}}, region: shire
            },
                dict{
                    id: tavern_loft, theme: village, type: indoor,
                    desc: "The quiet upper floor of the tavern. Soft straw beds line the walls under a wooden ceiling.",
                    exits: dict{downstairs: tavern}, props: [safe, bed], region: shire
            },
                dict{
                    id: temple, theme: monastery, type: indoor,
                    desc: "Sanctuary of Light. A grand cathedral housing the resplendent Altar of Sol. The air is thick with holy incense.",
                    exits: dict{crypt: graveyard, north: square}, props: [safe, altar_of_sol, ritual_circle], region: shire
            },
                dict{
                    id: barracks, theme: keep, type: indoor,
                    desc: "The town guard barracks. Weapon racks, shield braces, and training dummies line the stone walls.",
                    exits: dict{west: square, south: prison, tower: watchtower}, props: [safe, training_dummy], breakables: dict{rack_1: dict{type: crate, hp: 20}}, region: shire
            },
                dict{
                    id: watchtower, theme: keep, type: outdoor,
                    desc: "The high watchtower overlooking the shire. Banners flutter loudly in the strong wind.",
                    exits: dict{down: barracks}, props: [safe, windy], region: shire
            },
                dict{
                    id: prison, theme: prison, type: indoor,
                    desc: "The iron-barred dungeon. It is bleak, secure, and inescapable. Clangs of chains echo through the cells.",
                    exits: dict{north: barracks}, props: [prison, dark], region: shire
            },
                dict{
                    id: farm_field, theme: plains, type: outdoor,
                    desc: "A tilled farming field. Fertile soil stretches out in neat furrows under the open sky.",
                    exits: dict{east: orchard, south: windmill, town: square}, props: [safe, tilled], region: shire
            },
                dict{
                    id: orchard, theme: grove, type: outdoor,
                    desc: "A dense apple orchard. Sweet-smelling blossoms hang low from thick, sturdy branches.",
                    exits: dict{west: farm_field}, props: [safe], nodes: dict{apple_tree: dict{tag: oak_tree, qty: 5}}, region: shire
            },
                dict{
                    id: windmill, theme: village, type: indoor,
                    desc: "A towering wooden windmill. Large stone gears creak endlessly as they grind wheat into flour.",
                    exits: dict{north: farm_field}, props: [safe], region: shire
            },

                % --- SHIRE DUNGEON ENTRANCES ---
                dict{id: mine_entrance, theme: mine, type: normal, desc: "The dark, excavated entrance to an abandoned mine.", exits: dict{east: square}, props: []},
                dict{id: forest_trail, theme: forest, type: normal, desc: "A sprawling ancient canopy marking the edge of the woods.", exits: dict{town: square}, props: []},
                dict{id: graveyard, theme: crypt, type: normal, desc: "A dusty catacomb beneath the temple.", exits: dict{up: temple}, props: []},
                dict{id: mountain_trail, theme: volcano, type: normal, desc: "A steep and magmatic trail ascending into the clouds.", exits: dict{town: square}, props: []},

                % --- CROSSROADS & ROADS ---
                dict{
                    id: south_road, theme: plains, type: outdoor,
                    desc: "A well-trodden cobblestone highway leading south away from the Shire.",
                    exits: dict{town: square, south: crossroads}, props: [], region: roads
            },
                dict{
                    id: crossroads, theme: plains, type: outdoor,
                    desc: "A major intersection of trade roads. Signposts point towards the Shire, Porthaven, and Highforge.",
                    exits: dict{north: south_road, east: east_road, west: west_road, south: ruined_path, wild: 'cell_0_-5_0'}, props: [landmark], region: roads
            },
                dict{
                    id: east_road, theme: plains, type: outdoor,
                    desc: "A coastal breeze blows across this eastern trade route.",
                    exits: dict{west: crossroads, east: port_square, north: abandoned_keep_gate}, props: [], region: roads
            },
                dict{
                    id: west_road, theme: plains, type: outdoor,
                    desc: "The road inclines sharply here, winding towards the western peaks.",
                    exits: dict{east: crossroads, up: outpost_path}, props: [], region: roads
            },
                dict{
                    id: outpost_path, theme: volcano, type: outdoor,
                    desc: "A treacherous, rocky path ascending to the dwarven outpost.",
                    exits: dict{down: west_road, up: outpost_square}, props: [], region: roads
            },
                dict{
                    id: north_road, theme: forest, type: outdoor,
                    desc: "A serene, ancient forest path leading further north into the thick woods.",
                    exits: dict{south: square, north: sylvandell_square}, props: [], region: roads
            },

                % --- CROSSROADS DUNGEON ENTRANCES ---
                dict{id: ruined_path, theme: ruins, type: normal, desc: "A gloomy path choked with overgrowth leading into ancient ruins.", exits: dict{north: crossroads}, props: []},
                dict{id: abandoned_keep_gate, theme: keep, type: normal, desc: "The rusted, shattered portcullis of a fallen fortress.", exits: dict{south: east_road}, props: []},

                % --- PORTHAVEN (Eastern Coastal Settlement) ---
                dict{
                    id: port_square, theme: village, type: outdoor,
                    desc: "The bustling port square. Seagulls cry overhead and the smell of salt water hangs heavy. A local quest board stands near the pier.",
                    exits: dict{west: east_road, north: port_tavern, east: docks, south: fishery}, props: [safe, quest_board, landmark], region: porthaven
            },
                dict{
                    id: port_tavern, theme: village, type: indoor,
                    desc: "The Salty Sailor Inn. A cozy, low-ceilinged establishment serving grog and warm meals.",
                    exits: dict{south: port_square}, props: [safe, bed, oven], region: porthaven
            },
                dict{
                    id: docks, theme: village, type: outdoor,
                    desc: "Wooden docks stretching into the crashing sea. Ships bob gently in the tide.",
                    exits: dict{west: port_square, down: sunken_cove_entrance}, props: [safe, river], region: porthaven
            },
                dict{
                    id: fishery, theme: village, type: indoor,
                    desc: "A foul-smelling fishery filled with nets, salt, and today's catch.",
                    exits: dict{north: port_square}, props: [safe], region: porthaven
            },
                dict{id: sunken_cove_entrance, theme: cavern, type: normal, desc: "A slippery, algae-covered cavern plunging beneath the water level.", exits: dict{up: docks}, props: []},

                % --- HIGHFORGE (Western Mountain Outpost) ---
                dict{
                    id: outpost_square, theme: village, type: outdoor,
                    desc: "A fortified stone plaza carved directly into the mountain. The heat of massive forges radiates around the square. A rugged quest board is bolted to a pillar.",
                    exits: dict{down: outpost_path, north: smithy, east: high_inn, cave: deep_cavern_entrance}, props: [safe, quest_board, landmark], region: highforge
            },
                dict{
                    id: smithy, theme: village, type: indoor,
                    desc: "The Highforge Smithy. An intense, sweltering workshop where master artisans strike glowing steel.",
                    exits: dict{south: outpost_square}, props: [safe, oven], region: highforge
            },
                dict{
                    id: high_inn, theme: village, type: indoor,
                    desc: "The Stonehearth Inn. Carved from solid granite, offering incredibly secure (if somewhat hard) beds.",
                    exits: dict{west: outpost_square}, props: [safe, bed], region: highforge
            },
                dict{id: deep_cavern_entrance, theme: mine, type: normal, desc: "A gaping maw leading into the uncharted deep caverns.", exits: dict{out: outpost_square}, props: []},

                % --- SYLVANDELL (Northern Elven Enclave) ---
                dict{
                    id: sylvandell_square, theme: grove, type: outdoor,
                    desc: "The Moonlit Canopy. A breathtaking elven city suspended in giant ancient trees. An ornate quest board is carved into the central trunk.",
                    exits: dict{south: north_road, up: sylvandell_temple, down: deep_woods_entrance}, props: [safe, quest_board, landmark], region: sylvandell
            },
                dict{
                    id: sylvandell_temple, theme: monastery, type: indoor,
                    desc: "Shrine of the Silver Leaf. Peaceful, quiet, and humming with arcane energy.",
                    exits: dict{down: sylvandell_square}, props: [safe, healer], region: sylvandell
            },
                dict{id: deep_woods_entrance, theme: forest, type: normal, desc: "The edge of the Whispering Woods, a perilous and overgrown domain.", exits: dict{up: sylvandell_square}, props: []}
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
theme_node(ruins, _, ancient_relic).
theme_node(keep, _, scrap_metal).

seed_citizens :-
    Mobs = [
               % --- THE SHIRE NPCs ---
               mob{
                   id: guard_nycolas, tag: guard, name: "Guard Nycolas", lvl: 40,
                   hp: 300, max_hp: 300, mp: 30, max_mp: 30, str: 50, dex: 45, con: 50, int: 25, wis: 25, cha: 35, luk: 20,
                   room: square, fac: guard, props: [protector], equip: dict{wpn: iron_sword, shield: iron_shield, body: chainmail},
                   route: [square, barracks, prison], route_idx: 0, wander: false, threats: dict{}, mems: dict{}
           },
               mob{
                   id: peasant_bob, tag: peasant, name: "Bob the Farmer", lvl: 1,
                   hp: 30, max_hp: 30, mp: 10, max_mp: 10, str: 12, dex: 10, con: 14, int: 8, wis: 10, cha: 10, luk: 12,
                   room: square, fac: citizen, job: peasant, home: tavern, work: farm_field,
                   act_state: wander, props: [], equip: dict{wpn: fists, shield: none, body: tunic}, wander: true,
                   inv: [stack{tag: wheat_seed, qty: 3}, stack{tag: bread, qty: 2}], threats: dict{}, mems: dict{}
           },
               mob{
                   id: merchant_silvia, tag: merchant, name: "Silvia the Merchant", lvl: 5,
                   hp: 60, max_hp: 60, mp: 40, max_mp: 40, str: 10, dex: 12, con: 12, int: 14, wis: 15, cha: 18, luk: 15,
                   room: square, fac: merchant, job: merchant, home: tavern, work: square,
                   act_state: wander, props: [merchant], equip: dict{wpn: dagger, shield: none, body: tunic}, wander: false,
                   inv: [stack{tag: gold, qty: 500}, stack{tag: diviners_orb, qty: 1}, stack{tag: bread, qty: 10}, stack{tag: apple, qty: 10}, stack{tag: empty_waterskin, qty: 5}, stack{tag: flint_and_steel, qty: 2}, stack{tag: whetstone, qty: 2}], threats: dict{}, mems: dict{}
           },
               mob{
                   id: priest_luke, tag: priest, name: "Father Luke", lvl: 8,
                   hp: 80, max_hp: 80, mp: 80, max_mp: 80, str: 10, dex: 10, con: 12, int: 16, wis: 20, cha: 15, luk: 12,
                   room: temple, fac: citizen, job: citizen, home: temple, work: temple,
                   act_state: wander, props: [healer], equip: dict{wpn: staff, shield: none, body: tunic}, wander: false,
                   inv: [stack{tag: gold, qty: 100}, stack{tag: holy_water, qty: 5}], threats: dict{}, mems: dict{}
           },

               % --- PORTHAVEN NPCs ---
               mob{
                   id: guard_port, tag: guard, name: "Marine Sentinel", lvl: 25,
                   hp: 200, max_hp: 200, mp: 20, max_mp: 20, str: 35, dex: 30, con: 30, int: 15, wis: 15, cha: 20, luk: 15,
                   room: port_square, fac: guard, props: [protector, no_wander], equip: dict{wpn: sword, shield: wooden_shield, body: chainmail},
                   threats: dict{}, mems: dict{}
           },
               mob{
                   id: merchant_fish, tag: merchant, name: "Salty Pete", lvl: 10,
                   hp: 80, max_hp: 80, mp: 20, max_mp: 20, str: 15, dex: 18, con: 15, int: 12, wis: 12, cha: 25, luk: 20,
                   room: docks, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: dagger, shield: none, body: tunic},
                   inv: [stack{tag: gold, qty: 1200}, stack{tag: bread, qty: 15}, stack{tag: empty_waterskin, qty: 10}], threats: dict{}, mems: dict{}
           },

               % --- HIGHFORGE NPCs ---
               mob{
                   id: guard_high, tag: guard, name: "Dwarven Defender", lvl: 35,
                   hp: 350, max_hp: 350, mp: 10, max_mp: 10, str: 45, dex: 20, con: 50, int: 10, wis: 20, cha: 15, luk: 10,
                   room: outpost_square, fac: guard, props: [protector, no_wander], equip: dict{wpn: battleaxe, shield: iron_shield, body: dragon_scale_mail},
                   threats: dict{}, mems: dict{}
           },
               mob{
                   id: merchant_smith, tag: merchant, name: "Brokk the Forgemaster", lvl: 15,
                   hp: 120, max_hp: 120, mp: 50, max_mp: 50, str: 30, dex: 15, con: 30, int: 20, wis: 15, cha: 20, luk: 10,
                   room: smithy, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: sword, shield: none, body: tunic},
                   inv: [stack{tag: gold, qty: 3000}, stack{tag: iron_sword, qty: 3}, stack{tag: battleaxe, qty: 2}, stack{tag: chainmail, qty: 2}], threats: dict{}, mems: dict{}
           },

               % --- SYLVANDELL NPCs ---
               mob{
                   id: guard_elf, tag: guard, name: "Sylvan Warden", lvl: 30,
                   hp: 250, max_hp: 250, mp: 100, max_mp: 100, str: 30, dex: 50, con: 25, int: 35, wis: 30, cha: 20, luk: 20,
                   room: sylvandell_square, fac: guard, props: [protector, no_wander], equip: dict{wpn: elven_longbow, shield: none, body: tunic},
                   threats: dict{}, mems: dict{}
           },
               mob{
                   id: merchant_elf, tag: merchant, name: "Elora the Weaver", lvl: 20,
                   hp: 150, max_hp: 150, mp: 80, max_mp: 80, str: 15, dex: 30, con: 20, int: 30, wis: 35, cha: 40, luk: 25,
                   room: sylvandell_square, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: staff, shield: none, body: void_robe},
                   inv: [stack{tag: gold, qty: 4000}, stack{tag: elven_longbow, qty: 2}, stack{tag: mana_potion, qty: 15}, stack{tag: health_potion, qty: 15}, stack{tag: apple, qty: 30}], threats: dict{}, mems: dict{}
           },
               mob{
                   id: priest_elf, tag: priest, name: "High Priestess Lyra", lvl: 35,
                   hp: 300, max_hp: 300, mp: 500, max_mp: 500, str: 15, dex: 25, con: 25, int: 45, wis: 50, cha: 35, luk: 25,
                   room: sylvandell_temple, fac: citizen, props: [healer, no_wander], equip: dict{wpn: staff, shield: none, body: void_robe},
                   inv: [stack{tag: gold, qty: 2000}], threats: dict{}, mems: dict{}
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
