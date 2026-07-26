:- module(auth, [
              handle_validate_key/3,
              handle_login/3,
              handle_register/7,
              handle_disconnect/2
                ]).

:- use_module(library(md5)).
:- use_module('world').
:- use_module('entity').

handle_validate_key(Id, Key, [key_status(Id, Key, Status)]) :-
    ( admin_key(Key) -> Status = valid ; Status = invalid ).

handle_disconnect(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
        get_dict(room, Actor, RoomId),
        ( RoomId \== offline ->
            NActor = Actor.put(last_room, RoomId).put(room, offline),
            world:put_entity(NActor),
            world:save_db('world_state.json'),
            ( get_dict(name, Actor, Name) -> true ; get_dict(id, Actor, Name) ),
            format(string(Msg), "💨 ~w fades into the mist, disconnecting from the realm.", [Name]),
            world:push_room_event(RoomId, ambient_msg(Msg))
        ; true )
    ; true ),
    Evts = [].

restore_player_room(Player, NPlayer) :-
    get_dict(room, Player, RoomId),
    ( RoomId == offline ->
        ( get_dict(last_room, Player, LR) -> true ; LR = square ),
        NPlayer = Player.put(room, LR)
    ; NPlayer = Player ).

announce_login(Player) :-
    ( get_dict(name, Player, Name) -> true ; get_dict(id, Player, Name) ),
    get_dict(room, Player, RoomId),
    format(string(Msg), "✨ ~w manifests from the mist, entering the realm.", [Name]),
    world:push_room_event(RoomId, ambient_msg(Msg)).

handle_login(Id, Pass, Evts) :-
    hash_pass(Pass, Hash),
    ( world:get_entity(Id, Player) ->
          ( get_dict(pass_hash, Player, StoredHash) ->
                ( same_hash(StoredHash, Hash) ->
                      ( \+ get_dict(name, Player, _) ->
                            NPlayer = Player.put(name, Id)
                      ; NPlayer = Player ),
                      restore_player_room(NPlayer, NPlayer2),
                      world:put_entity(NPlayer2),
                      world:save_db('world_state.json'),
                      announce_login(NPlayer2),
                      Evts = [player_status(Id, exists)]
                ;
                  Evts = [error(invalid_password(Id))]
                )
          ;
            NPlayer = Player.put(pass_hash, Hash).put(name, Id),
            restore_player_room(NPlayer, NPlayer2),
            world:put_entity(NPlayer2),
            world:save_db('world_state.json'),
            announce_login(NPlayer2),
            Evts = [player_status(Id, exists)]
          )
    ;
      Evts = [error(account_does_not_exist(Id))]
    ).

% Strict Registration logic
handle_register(Id, Pass, Key, Race, Class, Stats, Evts) :-
    ( world:get_entity(Id, _) ->
          Evts = [error(account_already_exists(Id))]
    ;
      ( (is_restricted(Race), \+ admin_key(Key)) ->
            Evts = [error(restricted_race_denied(Id, Race))]
      ;
        ( admin_key(Key) -> IsAdmin = true ; IsAdmin = false ),
        ( chk_alloc(Stats, IsAdmin, CleanStats) ->
              default_player(Id, Pass, Race, Class, IsAdmin, CleanStats, NewPlayer),
              world:put_entity(NewPlayer),
              world:save_db('world_state.json'),
              ( get_dict(name, NewPlayer, Name) -> true ; get_dict(id, NewPlayer, Name) ),
              format(string(Msg), "✨ ~w manifests from the mist, entering the realm for the first time.", [Name]),
              world:push_room_event(square, ambient_msg(Msg)),
              Evts = [player_status(Id, created)]
        ;
          Evts = [error(stat_allocation_invalid(Id))]
        )
      )
    ).

same_hash(H1, H2) :-
    nonvar(H1), nonvar(H2),
    atom_string(H1, S1),
    atom_string(H2, S2),
    S1 == S2.

admin_key(RawKey) :-
    nonvar(RawKey),
    ( atom(RawKey) -> atom_string(RawKey, StrKey) ; StrKey = RawKey ),
    string(StrKey), normalize_space(string(CleanKey), StrKey),
    CleanKey \== "", is_admin_key_string(CleanKey).

is_admin_key_string("daotobavirus_supreme").
is_admin_key_string("SOL_ADMIN_1337").
is_admin_key_string("admin123").
is_admin_key_string("placeholder").

is_restricted(angel).
is_restricted(demon).

chk_alloc(Stats, IsAdmin, CleanStats) :-
    ( get_dict(str, Stats, S1) -> S is max(10, S1) ; S = 10 ),
    ( get_dict(dex, Stats, D1) -> D is max(10, D1) ; D = 10 ),
    ( get_dict(con, Stats, C1) -> C is max(10, C1) ; C = 10 ),
    ( get_dict(int, Stats, I1) -> I is max(10, I1) ; I = 10 ),
    ( get_dict(wis, Stats, W1) -> W is max(10, W1) ; W = 10 ),
    ( get_dict(cha, Stats, Ch1)-> Ch is max(10, Ch1); Ch = 10 ),
    ( get_dict(luk, Stats, L1) -> L is max(10, L1) ; L = 10 ),
    Spent is (S - 10) + (D - 10) + (C - 10) + (I - 10) + (W - 10) + (Ch - 10) + (L - 10),
    ( IsAdmin == true -> MaxPts = 100000 ; MaxPts = 15 ),
    Spent =< MaxPts,
    CleanStats = dict{str: S, dex: D, con: C, int: I, wis: W, cha: Ch, luk: L}.

hash_pass(Pass, HashStr) :-
    ( atom(Pass) ; string(Pass) ), Pass \== "", !,
    atom_string(Pass, Str),
    md5_hash(Str, RawHash, []),
    atom_string(RawHash, HashStr).
hash_pass(_, "nohash").

default_player(Id, Pass, Race, Class, IsAdmin, Stats, P) :-
    hash_pass(Pass, Hash),
    get_dict(str, Stats, S), get_dict(dex, Stats, D), get_dict(con, Stats, C),
    get_dict(int, Stats, I), get_dict(wis, Stats, W), get_dict(cha, Stats, Ch), get_dict(luk, Stats, L),
    TmpP = dict{race: Race, con: C, int: I},
    entity:get_stat(TmpP, con, TotalCon), entity:get_stat(TmpP, int, TotalInt),
    MaxHp is max(10, 50 + (TotalCon - 10) * 5), MaxMp is max(10, 20 + (TotalInt - 10) * 5),

    ( Race == angel -> StartingEquip = equip{wpn: seraphs_blade, shield: none, body: tunic}
    ; StartingEquip = equip{wpn: fists, shield: none, body: tunic} ),

    P = plyr{
            id: Id, name: Id, tag: player, class: Class, race: Race, lvl: 1, xp: 0,
            stat_points: 0, bounty: 0, pass_hash: Hash, admin: IsAdmin,
            hp: MaxHp, max_hp: MaxHp, mp: MaxMp, max_mp: MaxMp, affs: dict{},
            str: S, dex: D, con: C, int: I, wis: W, cha: Ch, luk: L,
            room: square, equip: StartingEquip,
            inv: [stack{tag: gold, qty: 100}], cds: cds{}
    }.
