:- module(chunks, [ensure_chunk/1]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('rng').
:- use_module('names').
:- use_module('spawn').
:- use_module('structures').

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

    % 1. Check if this chunk rolls a Rare Structure
    ( structures:check_special_structure(Hash, X, Y, Z, StructId, STheme, SName, SDesc, SProps) ->
        IsSpecial = true,
        Theme = STheme,
        Name = SName,
        Desc = SDesc,
        Props = SProps
    ;
        IsSpecial = false,
        ( Z < 0 -> Theme = cavern ; Theme = wild ),
        rng:gen_room_desc(Theme, Hash, Name, Desc, _),

        % Safe zone processing (only applies to normal chunks)
        world_config:safe_zone_chance(Theme, Chance),
        SafeRoll is (Hash // 100) mod 100,
        ( Chance > 0, SafeRoll < Chance -> Props = [safe] ; Props = [] )
    ),

    % 2. Calculate Local Environment (using structure overrides if special)
    ( IsSpecial == true, world_config:structure_env_base(StructId, BTemp, BMag, BCor) ->
        true
    ;
        world_config:theme_env_base(Theme, BTemp, BMag, BCor)
    ),

    TOff is (Hash mod 11) - 5, MOff is ((Hash // 11) mod 11) - 5, COff is ((Hash // 121) mod 11) - 5,
    Temp is BTemp + TOff, Mag is max(0, BMag + MOff), Cor is max(0, BCor + COff),
    REnv = dict{temp: Temp, magic: Mag, corr: Cor},

    % 3. Connect surrounding wilderness cells
    X1 is X + 1, chunk_id(X1, Y, Z, IdEast),
    X2 is X - 1, chunk_id(X2, Y, Z, IdWest),
    Y1 is Y + 1, chunk_id(X, Y1, Z, IdNorth),
    Y2 is Y - 1, chunk_id(X, Y2, Z, IdSouth),

    Exits0 = dict{north: IdNorth, south: IdSouth, east: IdEast, west: IdWest},
    ( Z > -5 -> Z1 is Z - 1, chunk_id(X, Y, Z1, IdDown), Exits1 = Exits0.put(down, IdDown) ; Exits1 = Exits0 ),
    ( Z < 5  -> Z2 is Z + 1, chunk_id(X, Y, Z2, IdUp),   Exits2 = Exits1.put(up, IdUp) ; Exits2 = Exits1 ),

    ( X == 0, Y == 0, Z == 0 -> FinalExits = Exits2.put(town, square) ; FinalExits = Exits2 ),

    Room = dict{id: Id, theme: Theme, type: outdoor, desc: Desc, name: Name, exits: FinalExits, props: Props, env: REnv},
    world:put_room(Room),

    % 4. Spawn Entities & Structural Features
    ( IsSpecial == true ->
        structures:spawn_structure_mobs(StructId, Hash, X, Y, Z, Theme, Id),
        structures:spawn_structure_features(StructId, Hash, Id)
    ;
        ( \+ member(safe, Props), (Hash mod 100) < 30 -> spawn_random_mob(Theme, Hash, X, Y, Z, Id) ; true )
    ).

spawn_random_mob(Theme, Hash, X, Y, Z, RId) :-
    Dist is sqrt(X*X + Y*Y + Z*Z*4),
    Lvl is max(1, floor(Dist / 2)),
    ( (Hash mod 100) < 5 -> Tier = elite ; Tier = normal ),
    spawn:gen_mob(Theme, Lvl, Tier, RId, Mob),
    world:put_entity(Mob).
