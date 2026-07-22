:- module(chunks, [ensure_chunk/3]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(names).
:- use_module(proc_spawn).
:- use_module(proc_loot).
:- use_module(zone).

ensure_chunk(W, cell(X, Y, Z), NW) :-
    \+ world:db_node(cell(X, Y, Z), _), !,
    generate_cell(W, X, Y, Z, NW).
ensure_chunk(W, _, W).

biome_terrain(village, stone).
biome_terrain(city, stone).
biome_terrain(market, stone).
biome_terrain(castle, stone).
biome_terrain(monastery, stone).
biome_terrain(forest, grass).
biome_terrain(plains, grass).
biome_terrain(swamp, mud).
biome_terrain(ruins, rubble).
biome_terrain(grove, grass).
biome_terrain(cavern, stone).
biome_terrain(mine, stone).
biome_terrain(sewer, mud).
biome_terrain(crypt, stone).
biome_terrain(tomb, stone).
biome_terrain(glacier, snow).
biome_terrain(frozen_lake, ice).
biome_terrain(volcano, hot_ash).
biome_terrain(inferno, hot_ash).
biome_terrain(_, grass).

generate_cell(W, X, Y, Z, NW) :-
    ( world:db_flag(world_seed, Seed) -> true ; Seed = 1337 ),
    Hash is (X * 73856093) xor (Y * 19349663) xor (Z * 83492791) xor Seed,
    get_biome(Y, Z, Hash, Biome, S1),
    names:gen_cell_name(Biome, S1, Name, S2),
    names:gen_cell_desc(Biome, Name, S2, Desc, S3),
    X1 is X + 1, X2 is X - 1, Y1 is Y + 1, Y2 is Y - 1,
    Exits0 = dict{north: cell(X, Y1, Z), south: cell(X, Y2, Z), east: cell(X1, Y, Z), west: cell(X2, Y, Z)},
    ( Z > -5 -> Z1 is Z - 1, Exits1 = Exits0.put(down, cell(X, Y, Z1)) ; Exits1 = Exits0 ),
    ( Z < 5 -> Z2 is Z + 1, Exits = Exits1.put(up, cell(X, Y, Z2)) ; Exits = Exits1 ),
    ( X == 0, Y == 0, Z == 0 -> FinalExits = Exits.put(town, square) ; FinalExits = Exits ),
    Dist is abs(X) + abs(Y) + abs(Z) * 3,
    Lvl is min(50, max(1, floor(Dist * 0.5))),
    roll_cell_props(Biome, S3, Props, S4),
    roll_cell_nodes(Biome, Lvl, S4, Nodes, S5),
    biome_terrain(Biome, Terr),
    Room0 = dict{id: cell(X, Y, Z), theme: Biome, type: outdoor, terrain: Terr, desc: Desc, name: Name, exits: FinalExits, props: Props, region: wilderness, lvl: Lvl},
    ( Nodes \== [] -> Room = Room0.put(nodes, Nodes) ; Room = Room0 ),
    assertz(world:db_node(cell(X, Y, Z), Room)),
    roll_cell_mobs(W, Biome, Lvl, cell(X, Y, Z), S5, W1, S6),
    roll_cell_chests(W1, Lvl, cell(X, Y, Z), S6, NW, _),
    assert_reverse_connections(W, X, Y, Z).

get_biome(Z, _, S, Biome, NS) :-
    Z < 0, !,
    names:lcg_member(S, [cavern, mine, sewer, crypt, tomb], Biome, NS).
get_biome(_, Y, S, Biome, NS) :-
    Y > 15, !,
    names:lcg_member(S, [glacier, frozen_lake], Biome, NS).
get_biome(_, Y, S, Biome, NS) :-
    Y < -15, !,
    names:lcg_member(S, [volcano, inferno], Biome, NS).
get_biome(_, Y, S, Biome, NS) :-
    abs(Y) < 5, !,
    names:lcg_member(S, [village, city, market], Biome, NS).
get_biome(_, _, S, Biome, NS) :-
    names:lcg_member(S, [forest, plains, swamp, ruins, grove], Biome, NS).

roll_cell_props(Biome, S, Props, NS) :-
    member(Biome, [crypt, tomb, prison, asylum, void, mine, cavern, sewer]), !,
    names:lcg_member(S, [[dark], [dark, silent], [dark, cold]], Props, NS).
roll_cell_props(volcano, S, [burning(I), hot], NS) :- !,
    names:lcg_range(S, 1, 3, I, NS).
roll_cell_props(inferno, S, [burning(I), hot, dark], NS) :- !,
    names:lcg_range(S, 2, 4, I, NS).
roll_cell_props(glacier, S, [cold, snow], NS) :- !,
    names:lcg(S, NS).
roll_cell_props(_, S, [], NS) :-
    names:lcg(S, NS).

roll_cell_nodes(Biome, Lvl, S, Nodes, NS) :-
    names:lcg_range(S, 1, 100, R, S1),
    ( R =< 30, theme_node(Biome, Lvl, Tag) ->
        names:lcg_range(S1, 3, 8, Qty, NS),
        random_between(100000, 999999, Rnd),
        atomic_list_concat([node_, Tag, '_', Rnd], NodeId),
        Nodes = dict{}.put(NodeId, dict{tag: Tag, qty: Qty})
    ;
        Nodes = [], NS = S1
    ).

theme_node(mine, Lvl, iron_vein) :- Lvl < 10, !.
theme_node(mine, Lvl, silver_vein) :- Lvl >= 10, Lvl < 20, !.
theme_node(mine, _, gold_vein).
theme_node(cavern, _, coal_vein).
theme_node(forest, _, oak_tree).
theme_node(grove, _, herb_patch).
theme_node(swamp, _, mushroom_patch).
theme_node(volcano, _, basalt_fissure).

roll_cell_mobs(W, Biome, Lvl, RId, S, NW, NS) :-
    names:lcg_range(S, 0, 3, Count, S1),
    spawn_cell_mobs(W, Count, Biome, Lvl, RId, S1, NW, NS).

spawn_cell_mobs(W, 0, _, _, _, S, W, S) :- !.
spawn_cell_mobs(W, Count, Biome, Lvl, RId, S, NW, NS) :-
    names:lcg_member(S, [normal, elite, boss], Tier, S1),
    proc_spawn:gen_mob(Biome, Lvl, Tier, RId, Mob),
    world:add(W, mob, Mob, W1),
    NCount is Count - 1,
    spawn_cell_mobs(W1, NCount, Biome, Lvl, RId, S1, NW, NS).

roll_cell_chests(W, Lvl, RId, S, NW, NS) :-
    names:lcg_range(S, 1, 100, R, S1),
    ( R =< 10 ->
        proc_loot:gen_chest(Lvl, RId, Items),
        forall(member(I, Items), assertz(world:db_entity(item, I.id, I))),
        NW = W, NS = S1
    ;
        NW = W, NS = S1
    ).

assert_reverse_connections(W, X, Y, Z) :-
    X1 is X + 1, X2 is X - 1, Y1 is Y + 1, Y2 is Y - 1,
    update_neighbor_exit(W, cell(X1, Y, Z), west, cell(X, Y, Z)),
    update_neighbor_exit(W, cell(X2, Y, Z), east, cell(X, Y, Z)),
    update_neighbor_exit(W, cell(X, Y1, Z), south, cell(X, Y, Z)),
    update_neighbor_exit(W, cell(X, Y2, Z), north, cell(X, Y, Z)).

update_neighbor_exit(W, TargetId, Dir, SrcId) :-
    world:db_node(TargetId, N), !,
    get_dict(exits, N, Ex),
    NEx = Ex.put(Dir, SrcId),
    zone:update_room(W, N.put(exits, NEx), _).
update_neighbor_exit(_, _, _, _).
