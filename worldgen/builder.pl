:- module(builder, [build_starter_world/0]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('dungeon').
:- use_module(library(random)).
:- use_module(library(lists)).

% ==============================================================================
% MAIN BUILD SEQUENCE
% ==============================================================================
build_starter_world :-
    world:clear_db,
    seed_hub,

    % --- Shire Dungeons (Lv 3 - 10) ---
    generate_and_merge(mine, 3, 6, mine_entrance),
    generate_and_merge(forest, 3, 8, forest_trail),
    generate_and_merge(crypt, 10, 8, graveyard),
    generate_and_merge(volcano, 25, 10, mountain_trail),

    % --- Mid-Tier Dungeons (Lv 12 - 25) ---
    generate_and_merge(ruins, 12, 10, ruined_path),
    generate_and_merge(keep, 35, 10, abandoned_keep_gate),
    generate_and_merge(cavern, 15, 12, sunken_cove_entrance),
    generate_and_merge(mine, 20, 15, deep_cavern_entrance),
    generate_and_merge(forest, 25, 12, deep_woods_entrance),

    % --- High-Tier & Endgame Dungeons (Lv 30 - 45) ---
    generate_and_merge(ruins, 30, 15, pyramid_entrance),
    generate_and_merge(cavern, 45, 20, ice_cavern_entrance),

    seed_citizens.

% ==============================================================================
% ROOM INITIALIZATION
% ==============================================================================
init_hub_room(R, NR) :-
    get_dict(theme, R, Theme),
    world_config:theme_env_base(Theme, BTemp, BMag, BCor),
    random_between(-5, 5, TOff),
    random_between(-5, 5, MOff),
    random_between(-5, 5, COff),
    Temp is BTemp + TOff,
    Mag is max(0, BMag + MOff),
    Cor is max(0, BCor + COff),
    NR = R.put(env, dict{temp: Temp, magic: Mag, corr: Cor}).

% ==============================================================================
% THE WORLD MAP (STATIC ZONES)
% ==============================================================================
seed_hub :-
    Rooms = [
        % ----------------------------------------------------------------------
        % THE SHIRE (Center / Starter Town)
        % ----------------------------------------------------------------------
        dict{
            id: square, theme: village, type: outdoor, region: shire,
            desc: "The central town square. A cool mountain river rushes past a stone fountain here. A large wooden board is covered with posted requests.",
            exits: dict{north: north_road, south: temple, east: barracks, west: mine_entrance, tavern: tavern, forest: forest_trail, farm: farm_field, mountain: mountain_trail, highway: south_road, wild: 'cell_0_0_0'},
            props: [safe, landmark, square, river, quest_board]
        },
        dict{
            id: tavern, theme: village, type: indoor, region: shire,
            desc: "The Rusty Flagon. A rowdy tavern complete with comfortable beds, heavy oak chairs, and a baking oven.",
            exits: dict{out: square, upstairs: tavern_loft},
            props: [safe, oven, tavern], furniture: dict{stool_1: dict{type: chair, user: none}}
        },
        dict{
            id: tavern_loft, theme: village, type: indoor, region: shire,
            desc: "The quiet upper floor of the tavern. Soft straw beds line the walls under a wooden ceiling.",
            exits: dict{downstairs: tavern}, props: [safe, bed]
        },
        dict{
            id: temple, theme: monastery, type: indoor, region: shire,
            desc: "Sanctuary of Light. A grand cathedral housing the resplendent Altar of Sol. The air is thick with holy incense.",
            exits: dict{crypt: graveyard, north: square}, props: [safe, altar_of_sol, ritual_circle]
        },
        dict{
            id: barracks, theme: keep, type: indoor, region: shire,
            desc: "The town guard barracks. Weapon racks, shield braces, and training dummies line the stone walls.",
            exits: dict{west: square, south: prison, tower: watchtower}, props: [safe, training_dummy], breakables: dict{rack_1: dict{type: crate, hp: 20}}
        },
        dict{
            id: watchtower, theme: keep, type: outdoor, region: shire,
            desc: "The high watchtower overlooking the shire. Banners flutter loudly in the strong wind.",
            exits: dict{down: barracks}, props: [safe, windy]
        },
        dict{
            id: prison, theme: prison, type: indoor, region: shire,
            desc: "The iron-barred dungeon. It is bleak, secure, and inescapable. Clangs of chains echo through the cells.",
            exits: dict{north: barracks}, props: [prison, dark]
        },
        dict{
            id: farm_field, theme: plains, type: outdoor, region: shire,
            desc: "A tilled farming field. Fertile soil stretches out in neat furrows under the open sky.",
            exits: dict{east: orchard, south: windmill, town: square}, props: [safe, tilled]
        },
        dict{
            id: orchard, theme: grove, type: outdoor, region: shire,
            desc: "A dense apple orchard. Sweet-smelling blossoms hang low from thick, sturdy branches.",
            exits: dict{west: farm_field}, props: [safe], nodes: dict{apple_tree: dict{tag: oak_tree, qty: 5}}
        },
        dict{
            id: windmill, theme: village, type: indoor, region: shire,
            desc: "A towering wooden windmill. Large stone gears creak endlessly as they grind wheat into flour.",
            exits: dict{north: farm_field}, props: [safe]
        },

        % Shire Dungeon Entrances
        dict{id: mine_entrance, theme: mine, type: normal, desc: "The dark, excavated entrance to an abandoned mine.", exits: dict{east: square}, props: []},
        dict{id: forest_trail, theme: forest, type: normal, desc: "A sprawling ancient canopy marking the edge of the woods.", exits: dict{town: square}, props: []},
        dict{id: graveyard, theme: crypt, type: normal, desc: "A dusty catacomb beneath the temple.", exits: dict{up: temple}, props: []},
        dict{id: mountain_trail, theme: volcano, type: normal, desc: "A steep and magmatic trail ascending into the clouds.", exits: dict{town: square}, props: []},

        % ----------------------------------------------------------------------
        % THE ROAD NETWORK
        % ----------------------------------------------------------------------
        dict{
            id: north_road, theme: forest, type: outdoor, region: roads,
            desc: "A serene, ancient forest path leading further north into the thick woods.",
            exits: dict{south: square, north: sylvandell_square}, props: []
        },
        dict{
            id: south_road, theme: plains, type: outdoor, region: roads,
            desc: "A well-trodden cobblestone highway leading south away from the Shire.",
            exits: dict{town: square, south: crossroads}, props: []
        },
        dict{
            id: crossroads, theme: plains, type: outdoor, region: roads,
            desc: "A major intersection of trade roads. Signposts point towards the Shire, Porthaven, Highforge, and Sunfang.",
            exits: dict{north: south_road, east: east_road, west: west_road, south: far_south_road, wild: 'cell_0_-5_0'}, props: [landmark]
        },
        dict{
            id: east_road, theme: plains, type: outdoor, region: roads,
            desc: "A coastal breeze blows across this eastern trade route.",
            exits: dict{west: crossroads, east: port_square, north: abandoned_keep_gate}, props: []
        },
        dict{
            id: west_road, theme: plains, type: outdoor, region: roads,
            desc: "The road inclines sharply here, winding towards the western peaks.",
            exits: dict{east: crossroads, up: outpost_path}, props: []
        },
        dict{
            id: outpost_path, theme: volcano, type: outdoor, region: roads,
            desc: "A treacherous, rocky path ascending to the dwarven outpost.",
            exits: dict{down: west_road, up: outpost_square}, props: []
        },
        dict{
            id: far_south_road, theme: plains, type: outdoor, region: roads,
            desc: "The climate grows blistering hot as this dusty road stretches far to the south.",
            exits: dict{north: crossroads, south: sunfang_square, east: ruined_path}, props: []
        },
        dict{
            id: frozen_path, theme: wild, type: outdoor, region: roads,
            desc: "A bitter, biting wind howls through this frozen, snow-choked mountain pass.",
            exits: dict{south: sylvandell_square, north: frosthold_square}, props: []
        },

        % Roads Dungeon Entrances
        dict{id: ruined_path, theme: ruins, type: normal, desc: "A gloomy path choked with overgrowth leading into ancient ruins.", exits: dict{west: far_south_road}, props: []},
        dict{id: abandoned_keep_gate, theme: keep, type: normal, desc: "The rusted, shattered portcullis of a fallen fortress.", exits: dict{south: east_road}, props: []},

        % ----------------------------------------------------------------------
        % PORTHAVEN (East)
        % ----------------------------------------------------------------------
        dict{
            id: port_square, theme: village, type: outdoor, region: porthaven,
            desc: "The bustling port square. Seagulls cry overhead and the smell of salt water hangs heavy. A local quest board stands near the pier.",
            exits: dict{west: east_road, north: port_tavern, east: docks, south: fishery}, props: [safe, quest_board, landmark]
        },
        dict{
            id: port_tavern, theme: village, type: indoor, region: porthaven,
            desc: "The Salty Sailor Inn. A cozy, low-ceilinged establishment serving grog and warm meals.",
            exits: dict{south: port_square}, props: [safe, bed, oven]
        },
        dict{
            id: docks, theme: village, type: outdoor, region: porthaven,
            desc: "Wooden docks stretching into the crashing sea. Ships bob gently in the tide.",
            exits: dict{west: port_square, down: sunken_cove_entrance}, props: [safe, river]
        },
        dict{
            id: fishery, theme: village, type: indoor, region: porthaven,
            desc: "A foul-smelling fishery filled with nets, salt, and today's catch.",
            exits: dict{north: port_square}, props: [safe]
        },
        dict{id: sunken_cove_entrance, theme: cavern, type: normal, desc: "A slippery, algae-covered cavern plunging beneath the water level.", exits: dict{up: docks}, props: []},

        % ----------------------------------------------------------------------
        % HIGHFORGE (West)
        % ----------------------------------------------------------------------
        dict{
            id: outpost_square, theme: village, type: outdoor, region: highforge,
            desc: "A fortified stone plaza carved directly into the mountain. The heat of massive forges radiates around the square. A rugged quest board is bolted to a pillar.",
            exits: dict{down: outpost_path, north: smithy, east: high_inn, cave: deep_cavern_entrance}, props: [safe, quest_board, landmark]
        },
        dict{
            id: smithy, theme: village, type: indoor, region: highforge,
            desc: "The Highforge Smithy. An intense, sweltering workshop where master artisans strike glowing steel.",
            exits: dict{south: outpost_square}, props: [safe, oven]
        },
        dict{
            id: high_inn, theme: village, type: indoor, region: highforge,
            desc: "The Stonehearth Inn. Carved from solid granite, offering incredibly secure (if somewhat hard) beds.",
            exits: dict{west: outpost_square}, props: [safe, bed]
        },
        dict{id: deep_cavern_entrance, theme: mine, type: normal, desc: "A gaping maw leading into the uncharted deep caverns.", exits: dict{out: outpost_square}, props: []},

        % ----------------------------------------------------------------------
        % SYLVANDELL (North)
        % ----------------------------------------------------------------------
        dict{
            id: sylvandell_square, theme: grove, type: outdoor, region: sylvandell,
            desc: "The Moonlit Canopy. A breathtaking elven city suspended in giant ancient trees. An ornate quest board is carved into the central trunk.",
            exits: dict{south: north_road, north: frozen_path, up: sylvandell_temple, down: deep_woods_entrance}, props: [safe, quest_board, landmark]
        },
        dict{
            id: sylvandell_temple, theme: monastery, type: indoor, region: sylvandell,
            desc: "Shrine of the Silver Leaf. Peaceful, quiet, and humming with arcane energy.",
            exits: dict{down: sylvandell_square}, props: [safe, healer]
        },
        dict{id: deep_woods_entrance, theme: forest, type: normal, desc: "The edge of the Whispering Woods, a perilous and overgrown domain.", exits: dict{up: sylvandell_square}, props: []},

        % ----------------------------------------------------------------------
        % SUNFANG OASIS (South)
        % ----------------------------------------------------------------------
        dict{
            id: sunfang_square, theme: village, type: outdoor, region: sunfang,
            desc: "A blistering desert settlement built around a life-giving oasis. Silken canopies provide shade over a dusty quest board.",
            exits: dict{north: far_south_road, east: sunfang_bazaar, west: sunfang_tents, down: pyramid_entrance}, props: [safe, quest_board, landmark, river]
        },
        dict{
            id: sunfang_bazaar, theme: village, type: outdoor, region: sunfang,
            desc: "A sprawling open-air market smelling of exotic spices and roasted meats.",
            exits: dict{west: sunfang_square}, props: [safe]
        },
        dict{
            id: sunfang_tents, theme: village, type: indoor, region: sunfang,
            desc: "Large, opulent sleeping tents lined with plush desert rugs and pillows.",
            exits: dict{east: sunfang_square}, props: [safe, bed]
        },
        dict{id: pyramid_entrance, theme: ruins, type: normal, desc: "The towering, sand-scoured entrance to an ancient pyramid.", exits: dict{up: sunfang_square}, props: []},

        % ----------------------------------------------------------------------
        % FROSTHOLD (Far North)
        % ----------------------------------------------------------------------
        dict{
            id: frosthold_square, theme: keep, type: outdoor, region: frosthold,
            desc: "A heavily fortified courtyard encased in eternal ice. The biting wind is unrelenting. A quest board is bolted to the frozen stone.",
            exits: dict{south: frozen_path, north: frosthold_keep, down: ice_cavern_entrance}, props: [safe, quest_board, landmark]
        },
        dict{
            id: frosthold_keep, theme: keep, type: indoor, region: frosthold,
            desc: "The inner sanctum of Frosthold. A massive hearth fire roars in the center, surrounded by fur-lined cots.",
            exits: dict{south: frosthold_square}, props: [safe, bed, oven]
        },
        dict{id: ice_cavern_entrance, theme: cavern, type: normal, desc: "A sheer drop into a labyrinth of glowing blue ice caves.", exits: dict{up: frosthold_square}, props: []}
    ],
    maplist(init_hub_room, Rooms, FinalRooms),
    forall(member(R, FinalRooms), world:put_room(R)).

% ==============================================================================
% DUNGEON MERGING LOGIC
% ==============================================================================
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
          ( get_dict(nodes, R, Nodes) -> NNodes = Nodes.put(NodeId, dict{tag: Tag, qty: Qty})
          ; NNodes = dict{}.put(NodeId, dict{tag: Tag, qty: Qty}) ),
          NR = R.put(nodes, NNodes)
    ; NR = R ).

% Resource Mapping
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

% ==============================================================================
% NPC & CITIZEN POPULATION
% ==============================================================================
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
        mob{
            id: merchant_armorer, tag: merchant, name: "Garrick the Armorer", lvl: 15,
            hp: 120, max_hp: 120, mp: 30, max_mp: 30, str: 25, dex: 15, con: 25, int: 14, wis: 15, cha: 20, luk: 10,
            room: barracks, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: sword, shield: iron_shield, body: chainmail},
            inv: [stack{tag: gold, qty: 2000}, stack{tag: chainmail, qty: 3}, stack{tag: plate_mail, qty: 2}, stack{tag: wooden_shield, qty: 3}, stack{tag: iron_shield, qty: 2}, stack{tag: runic_shield, qty: 1}],
            threats: dict{}, mems: dict{}
        },

        % --- CROSSROADS NPCs ---
        mob{
            id: merchant_crossroads, tag: merchant, name: "Wandering Otto", lvl: 10,
            hp: 90, max_hp: 90, mp: 30, max_mp: 30, str: 15, dex: 18, con: 15, int: 12, wis: 14, cha: 25, luk: 20,
            room: crossroads, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: dagger, shield: none, body: tunic},
            inv: [stack{tag: gold, qty: 1500}, stack{tag: whetstone, qty: 10}, stack{tag: flint_and_steel, qty: 10}, stack{tag: empty_waterskin, qty: 10}, stack{tag: shortbow, qty: 3}, stack{tag: bread, qty: 20}],
            threats: dict{}, mems: dict{}
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
        mob{
            id: merchant_smuggler, tag: merchant, name: "Sly Corren the Smuggler", lvl: 18,
            hp: 110, max_hp: 110, mp: 40, max_mp: 40, str: 18, dex: 30, con: 18, int: 16, wis: 12, cha: 30, luk: 35,
            room: port_tavern, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: pirate_cutlass, shield: none, body: tunic},
            inv: [stack{tag: gold, qty: 3500}, stack{tag: pirate_cutlass, qty: 3}, stack{tag: katana, qty: 1}, stack{tag: pica_de_inseto, qty: 2}, stack{tag: witch_brew, qty: 3}],
            threats: dict{}, mems: dict{}
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
        mob{
            id: merchant_jeweler, tag: merchant, name: "Gilmora the Gemcutter", lvl: 25,
            hp: 150, max_hp: 150, mp: 100, max_mp: 100, str: 10, dex: 20, con: 20, int: 30, wis: 30, cha: 40, luk: 30,
            room: outpost_square, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: dagger, shield: none, body: royal_attire},
            inv: [stack{tag: gold, qty: 5000}, stack{tag: blood_ruby, qty: 2}, stack{tag: astral_shard, qty: 3}, stack{tag: diviners_orb, qty: 1}, stack{tag: runic_shield, qty: 1}],
            threats: dict{}, mems: dict{}
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
        },

        % --- SUNFANG OASIS NPCs ---
        mob{
            id: guard_sunfang, tag: guard, name: "Desert Sentinel", lvl: 35,
            hp: 300, max_hp: 300, mp: 50, max_mp: 50, str: 40, dex: 35, con: 40, int: 15, wis: 15, cha: 20, luk: 25,
            room: sunfang_square, fac: guard, props: [protector, no_wander], equip: dict{wpn: greatsword, shield: none, body: chainmail},
            threats: dict{}, mems: dict{}
        },
        mob{
            id: merchant_sunfang, tag: merchant, name: "Kasim the Trader", lvl: 20,
            hp: 120, max_hp: 120, mp: 50, max_mp: 50, str: 15, dex: 25, con: 15, int: 25, wis: 25, cha: 45, luk: 35,
            room: sunfang_bazaar, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: dagger, shield: none, body: tunic},
            inv: [stack{tag: gold, qty: 6000}, stack{tag: mana_potion, qty: 10}, stack{tag: health_potion, qty: 10}, stack{tag: apple, qty: 15}], threats: dict{}, mems: dict{}
        },
        mob{
            id: merchant_nomad, tag: merchant, name: "Tariq the Weaponmonger", lvl: 22,
            hp: 160, max_hp: 160, mp: 30, max_mp: 30, str: 35, dex: 25, con: 30, int: 15, wis: 15, cha: 35, luk: 20,
            room: sunfang_bazaar, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: morningstar, shield: none, body: demon_hide},
            inv: [stack{tag: gold, qty: 4500}, stack{tag: morningstar, qty: 2}, stack{tag: orcish_cleaver, qty: 2}, stack{tag: greatsword, qty: 2}, stack{tag: golden_aegis, qty: 1}],
            threats: dict{}, mems: dict{}
        },

        % --- FROSTHOLD NPCs ---
        mob{
            id: guard_frost, tag: guard, name: "Frostguard Elite", lvl: 45,
            hp: 500, max_hp: 500, mp: 50, max_mp: 50, str: 60, dex: 30, con: 60, int: 20, wis: 25, cha: 15, luk: 15,
            room: frosthold_square, fac: guard, props: [protector, no_wander], equip: dict{wpn: battleaxe, shield: iron_shield, body: plate_mail},
            threats: dict{}, mems: dict{}
        },
        mob{
            id: merchant_frost, tag: merchant, name: "Ylva the Quartermaster", lvl: 25,
            hp: 200, max_hp: 200, mp: 50, max_mp: 50, str: 25, dex: 20, con: 30, int: 25, wis: 25, cha: 30, luk: 20,
            room: frosthold_keep, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: sword, shield: none, body: chainmail},
            inv: [stack{tag: gold, qty: 8000}, stack{tag: health_potion, qty: 25}, stack{tag: bread, qty: 30}, stack{tag: iron_sword, qty: 2}, stack{tag: battleaxe, qty: 1}], threats: dict{}, mems: dict{}
        },
        mob{
            id: merchant_alchemist, tag: merchant, name: "Kaelen the Alchemist", lvl: 30,
            hp: 180, max_hp: 180, mp: 300, max_mp: 300, str: 12, dex: 20, con: 22, int: 40, wis: 35, cha: 25, luk: 20,
            room: frosthold_keep, fac: merchant, props: [merchant, no_wander], equip: dict{wpn: staff, shield: none, body: mage_robe},
            inv: [stack{tag: gold, qty: 6000}, stack{tag: health_potion, qty: 30}, stack{tag: mana_potion, qty: 30}, stack{tag: witch_brew, qty: 10}],
            threats: dict{}, mems: dict{}
        }
    ],
    forall(member(M, Mobs), world:put_entity(M)),

    % Universal Floor Loot for the Shire Square
    Items = [
        item{id: floor_hoe, tag: hoe, qty: 1, room: square},
        item{id: floor_pole, tag: fishing_pole, qty: 1, room: square},
        item{id: floor_flint, tag: flint_and_steel, qty: 1, room: square},
        item{id: floor_skin, tag: empty_waterskin, qty: 1, room: square}
    ],
    forall(member(I, Items), world:put_entity(I)).
