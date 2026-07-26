:- module(ai, [do_ai_tick/1, check_and_spawn_settlement_npc/1]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../core/events').
:- use_module('../config/spawn').
:- use_module('../worldgen/spawn').
:- use_module('../worldgen/structures').
:- use_module('combat').
:- use_module('move').
:- use_module('status').
:- use_module(library(random)).
:- use_module(library(lists)).

do_ai_tick(Evts) :-
    world:all_mobs(Mobs),
    process_mobs(Mobs, MEvts),
    replenish_settlements,
    replenish_guards,
    replenish_livestock,
    structures:tick_respawns(REvts),
    handle_world_events(WEvts),
    append(MEvts, REvts, Tmp1),
    append(Tmp1, WEvts, Evts).

handle_world_events(Evts) :-
    world:env_state(Env),
    ( get_dict(active_event, Env, blood_moon) ->
        random_between(1, 100, Roll),
        ( Roll =< 3 ->
            Towns = [square, crossroads, port_square, outpost_square, sylvandell_square, sunfang_square, frosthold_square],
            random_member(Town, Towns),
            spawn:gen_mob(volcano, 25, normal, Town, Demon),
            world:put_entity(Demon),
            combat:get_display_name(Demon, DName),
            ( world:get_room(Town, Room) -> get_dict(name, Room, RName) ; RName = Town ),
            format(string(Msg), "🩸 A portal tears open in ~w! A ~w emerges from the Abyss!", [RName, DName]),
            % Broadcast globally so players feel the panic
            forall(world:get_room(AllRId, _), world:push_room_event(AllRId, env_msg(Msg))),
            Evts = []
        ; Evts = [] )
    ; Evts = [] ).

process_mobs([], []).
process_mobs([Mob|T], Evts) :-
    get_dict(id, Mob, MobId),
    ( get_dict(room, Mob, RoomId) -> true ; RoomId = square ),

    status:do_tick(MobId, TickEvts),
    events:split_events(TickEvts, PubTick, _),
    ( PubTick \== [] -> world:push_room_events(RoomId, PubTick) ; true ),

    ( world:get_entity(MobId, FreshMob), entity:is_alive(FreshMob) ->
          ( act_mob(FreshMob, AEvt) -> true ; AEvt = [] )
    ; AEvt = [] ),

    process_mobs(T, REvts),
    append(TickEvts, AEvt, TmpEvts),
    append(TmpEvts, REvts, Evts).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

is_settlement_room(Room) :-
    ( get_dict(theme, Room, Theme), member(Theme, [village, keep, monastery, town]) ;
      get_dict(props, Room, Props), (member(safe, Props) ; member(landmark, Props)) ;
      get_dict(region, Room, shire) ), !.

is_no_wander(Mob) :-
    get_dict(tag, Mob, merchant), !.
is_no_wander(Mob) :-
    get_dict(owner, Mob, _), !.
is_no_wander(Mob) :-
    ( get_dict(wander, Mob, false)
    ; get_dict(props, Mob, Props), (member(no_wander, Props) ; member(merchant, Props))
    ), !.

valid_npc_move(Mob, NextRoomId) :-
    world:get_room(NextRoomId, NextRoom),
    ( get_dict(tag, Mob, royal_guard) ->
          is_settlement_room(NextRoom)
    ; get_dict(tag, Mob, guard) ->
          true % Patrolling guards are permitted to wander into the wild
    ; combat:is_livestock(Mob) ->
          member(NextRoomId, [farm_field, orchard, windmill]) % Bounded strictly to farming grounds
    ; combat:is_town_npc(Mob) ->
          is_settlement_room(NextRoom)
    ;
      true
    ).

is_hostile_mob(Mob) :-
    get_dict(tag, Mob, Tag),
    to_atom(Tag, AtomTag),
    spawn_config:is_aggressive(AtomTag).

highest_bounty(Ents, TopId) :-
    findall(B-Id, (
                member(E, Ents),
                get_dict(bounty, E, B), B > 0,
                get_dict(id, E, Id),
                entity:is_alive(E),
                \+ entity:has_aff(E, stealthed) % Guards cannot see stealthed criminals
                  ), Pairs),
    Pairs \== [],
    keysort(Pairs, Sorted),
    reverse(Sorted, [_-TopId|_]).

% Guard attacks criminals
act_mob(Mob, Evts) :-
    combat:is_guard(Mob),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    highest_bounty(Ents, TgtId), !,
    get_dict(id, Mob, MId),
    combat:do_kill(MId, TgtId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Summons intelligently attack their owner's enemies
act_mob(Mob, Evts) :-
    get_dict(owner, Mob, _OwnerId),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    member(Tgt, Ents),
    entity:is_alive(Tgt),
    \+ entity:has_aff(Tgt, stealthed), % Summons cannot see stealthed targets
    combat:is_enemy(Mob, Tgt), !,
    get_dict(id, Mob, MId), get_dict(id, Tgt, TgtId),
    combat:do_kill(MId, TgtId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Mobs respond to threats
act_mob(Mob, Evts) :-
    get_dict(room, Mob, Room),
    get_dict(threats, Mob, Threats),
    dict_keys(Threats, Keys), Keys \== [],
    world:room_entities(Room, Ents),
    member(Tgt, Ents),
    get_dict(id, Tgt, TgtId),
    member(TgtId, Keys),
    entity:is_alive(Tgt),
    \+ entity:has_aff(Tgt, stealthed), !, % Cannot retaliate against a stealthed threat
    get_dict(id, Mob, MId),
    combat:do_kill(MId, TgtId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Guard attacks ANY unowned monster (maintains safety in towns & aggressively cleanses roads)
act_mob(Mob, Evts) :-
    combat:is_guard(Mob),
    get_dict(room, Mob, Room),
    world:room_entities(Room, Ents),
    member(Monster, Ents),
    is_dict(Monster, mob),
    \+ get_dict(owner, Monster, _),
    get_dict(id, Monster, MonId),
    get_dict(id, Mob, GuardId),
    MonId \== GuardId,
    \+ combat:is_innocent(Monster),
    \+ combat:is_livestock(Monster), % Guards ignore harmless farm livestock
    entity:is_alive(Monster),
    \+ entity:has_aff(Monster, stealthed), !, % Cannot target stealthed monsters
    combat:do_kill(GuardId, MonId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

% Hostile mob attacks player
act_mob(Mob, Evts) :-
    get_dict(room, Mob, Room),
    \+ get_dict(owner, Mob, _),
    is_hostile_mob(Mob),
    world:room_entities(Room, Ents),
    member(P, Ents), is_dict(P, plyr),
    entity:is_alive(P),
    \+ entity:has_aff(P, stealthed), !, % Cannot automatically aggro a stealthed player
    get_dict(id, P, PId), get_dict(id, Mob, MId),
    combat:do_kill(MId, PId, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

act_mob(Mob, Evts) :-
    \+ is_no_wander(Mob),
    random_between(1, 100, R), R =< 2, !,
    get_dict(room, Mob, Room),
    world:get_room(Room, RoomNode),
    get_dict(exits, RoomNode, ExitsDict),
    dict_keys(ExitsDict, Exits), Exits \== [],
    random_member(Dir, Exits),
    get_dict(Dir, ExitsDict, NextRoomId),
    valid_npc_move(Mob, NextRoomId), !,
    get_dict(id, Mob, MId),
    move:do_move(MId, Dir, RawEvts),
    events:split_events(RawEvts, PubEvts, _PrivEvts),
    world:push_room_events(Room, PubEvts),
    Evts = PubEvts.

replenish_guards :-
    Hubs = [square, port_square, outpost_square, sylvandell_square, sunfang_square, frosthold_square],
    forall(member(Hub, Hubs), (
        findall(M, (
            world:db_entity(_, M),
            is_dict(M, mob),
            get_dict(tag, M, royal_guard),
            get_dict(home, M, Hub),
            entity:is_alive(M)
        ), HubGuards),
        length(HubGuards, Count),
        ( Count < 2, random_between(1, 100, Roll), Roll =< 5 ->
            spawn:gen_royal_guard_npc(Hub, NewG),
            world:put_entity(NewG),
            get_dict(name, NewG, Name),
            world:push_room_event(Hub, npc_arrived(Name))
        ; true )
    )),
    findall(M, (
        world:db_entity(_, M),
        is_dict(M, mob),
        get_dict(tag, M, guard),
        entity:is_alive(M)
    ), PatrolGuards),
    length(PatrolGuards, PCount),
    ( PCount < 4, random_between(1, 100, PRoll), PRoll =< 5 ->
        Roads = [crossroads, north_road, south_road, east_road, west_road],
        random_member(SpawnRoad, Roads),
        spawn:gen_patrol_guard_npc(SpawnRoad, NewP),
        world:put_entity(NewP),
        get_dict(name, NewP, PName),
        world:push_room_event(SpawnRoad, npc_arrived(PName))
    ; true ).

replenish_livestock :-
    LivestockRooms = [farm_field, orchard, windmill],
    forall(member(Room, LivestockRooms), (
        world:room_entities(Room, Ents),
        findall(M, (
            member(M, Ents),
            is_dict(M, mob),
            get_dict(tag, M, Tag),
            member(Tag, [chicken, pig, sheep, cow]),
            entity:is_alive(M)
        ), Livestock),
        length(Livestock, Count),
        ( Count < 3, random_between(1, 100, Roll), Roll =< 15 ->
            random_member(LTag, [chicken, pig, sheep, cow]),
            spawn:gen_livestock_npc(Room, LTag, NewNpc),
            world:put_entity(NewNpc),
            get_dict(name, NewNpc, Name),
            format(string(Msg), "A ~w wanders into the area.", [Name]),
            world:push_room_event(Room, ambient_msg(Msg))
        ; true )
    )).

replenish_settlements :-
    findall(M, (
                world:db_entity(_, M),
                is_dict(M, mob),
                get_dict(hp, M, Hp), Hp > 0,
                get_dict(room, M, RId),
                world:get_room(RId, RNode),
                is_settlement_room(RNode)
               ), TownMobs),
    length(TownMobs, TotalTownMobs),
    ( TotalTownMobs < 12 ->
          random_between(1, 100, Roll),
          ( Roll =< 5 ->
                spawn:gen_town_npc(square, NewNpc),
                world:put_entity(NewNpc),
                get_dict(name, NewNpc, Name),
                world:push_room_event(square, npc_arrived(Name))
          ; true )
    ; true ).

check_and_spawn_settlement_npc(_) :- true.
