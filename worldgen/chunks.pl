:- module(chunks, [ensure_chunk/1]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('rng').
:- use_module('names').

chunk_id(X, Y, Z, Id) :- atomic_list_concat(['cell', X, Y, Z], '_', Id).

ensure_chunk(Id) :-
    atom(Id),
    atomic_list_concat(['cell', XStr, YStr, ZStr], '_', Id),
    atom_number(XStr, X), atom_number(YStr, Y), atom_number(ZStr, Z),
    \+ world:get_room(Id, _), !,
    generate_cell(X, Y, Z, Id).
ensure_chunk(_).

generate_cell(X, Y, Z, Id) :-
    Seed = 1337,
    Hash is (X * 73856093) xor (Y * 19349663) xor (Z * 83492791) xor Seed,

    ( Z < 0 -> Theme = cavern ; Theme = wild ),
    rng:gen_room_desc(Theme, Hash, Name, Desc, _),

    world_config:safe_zone_chance(Theme, Chance),
    SafeRoll is (Hash // 100) mod 100,
    ( Chance > 0, SafeRoll < Chance ->
        Props = [safe]
    ; Props = [] ),

    X1 is X + 1, chunk_id(X1, Y, Z, IdEast),
    X2 is X - 1, chunk_id(X2, Y, Z, IdWest),
    Y1 is Y + 1, chunk_id(X, Y1, Z, IdNorth),
    Y2 is Y - 1, chunk_id(X, Y2, Z, IdSouth),

    Exits0 = dict{north: IdNorth, south: IdSouth, east: IdEast, west: IdWest},
    ( Z > -5 -> Z1 is Z - 1, chunk_id(X, Y, Z1, IdDown), Exits1 = Exits0.put(down, IdDown) ; Exits1 = Exits0 ),
    ( Z < 5  -> Z2 is Z + 1, chunk_id(X, Y, Z2, IdUp),   Exits2 = Exits1.put(up, IdUp) ; Exits2 = Exits1 ),

    ( X == 0, Y == 0, Z == 0 -> FinalExits = Exits2.put(town, square) ; FinalExits = Exits2 ),

    Room = dict{id: Id, theme: Theme, type: outdoor, desc: Desc, name: Name, exits: FinalExits, props: Props},
    world:put_room(Room),

    ( \+ member(safe, Props), (Hash mod 100) < 30 -> spawn_random_mob(Theme, Hash, Id) ; true ).

spawn_random_mob(Theme, Hash, RId) :-
    ( Theme == wild -> Tag = wolf ; Tag = goblin ),
    world:gen_id(mob, MId),

    names:gen_creature_name(Hash, GeneratedName, _),

    Mob = mob{id: MId, tag: Tag, name: GeneratedName, lvl: 1, hp: 20, max_hp: 20, str: 10, dex: 10, int: 10, room: RId},
    world:put_entity(Mob).
