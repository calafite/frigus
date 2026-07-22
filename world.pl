:- module(world, [
    entity/3, node/3, add/4,
    update/3, remove/3, room_entities/3,
    flags/2, flags/3,
    load_db/1, dump_db/1, clear_db/0,
    db_entity/3, db_node/2, db_flag/2
]).

:- dynamic db_entity/3.
:- dynamic db_node/2.
:- dynamic db_flag/2.

entity(_, Id, E) :- db_entity(_, Id, E), !.

node(_, Id, N) :- db_node(Id, N), !.

add(_, Type, E, db) :-
    assertz(db_entity(Type, E.id, E)).

update(_, E, db) :-
    ( db_entity(Type, E.id, _) ->
        retractall(db_entity(Type, E.id, _)),
        assertz(db_entity(Type, E.id, E))
    ; db_node(E.id, _) ->
        retractall(db_node(E.id, _)),
        assertz(db_node(E.id, E))
    ).

remove(_, Id, db) :-
    retractall(db_entity(_, Id, _)),
    retractall(db_node(Id, _)).

room_entities(_, RId, Ents) :-
    findall(E, (
        db_entity(_, _, E),
        get_dict(room, E, RId)
    ), Ents).

flags(_, Fs) :-
    findall(K-V, db_flag(K, V), Pairs),
    dict_pairs(Fs, flags, Pairs).

flags(_, Fs, db) :-
    retractall(db_flag(_, _)),
    dict_pairs(Fs, flags, Pairs),
    forall(member(K-V, Pairs), assertz(db_flag(K, V))).

load_db(State) :-
    clear_db,
    ( get_dict(plyrs, State, Plyrs) -> forall(member(P, Plyrs), assertz(db_entity(plyr, P.id, P))) ; true ),
    ( get_dict(mobs, State, Mobs) -> forall(member(M, Mobs), assertz(db_entity(mob, M.id, M))) ; true ),
    ( get_dict(items, State, Items) -> forall(member(I, Items), assertz(db_entity(item, I.id, I))) ; true ),
    ( get_dict(rooms, State, Rooms) -> forall(member(R, Rooms), assertz(db_node(R.id, R))) ; true ),
    ( get_dict(flags, State, Fs) ->
        dict_pairs(Fs, flags, Pairs),
        forall(member(K-V, Pairs), assertz(db_flag(K, V)))
    ; true ),
    ( get_dict(env, State, Env) -> assertz(env:db_env(Env)) ; true ),
    ( get_dict(social, State, Soc) -> assertz(social:db_social(Soc)) ; true ),
    ( get_dict(market, State, Mkt) ->
        dict_pairs(Mkt, market, Pairs),
        forall(member(RId-Items, Pairs), (
            dict_pairs(Items, items, IPairs),
            forall(member(ITag-Qty, IPairs), assertz(economy:db_market_supply(RId, ITag, Qty)))
        ))
    ; true ),
    ( get_dict(quests, State, Qs) ->
        forall(member(Q, Qs), assertz(quest_gen:db_generated_quest(Q.npc, Q.id, Q.objs, Q.rews)))
    ; true ).

dump_db(State) :-
    findall(P, db_entity(plyr, _, P), Plyrs),
    findall(M, db_entity(mob, _, M), Mobs),
    findall(I, db_entity(item, _, I), Items),
    findall(R, db_node(_, R), Rooms),
    flags(db, Fs),
    ( env:db_env(Env) -> true ; Env = env{} ),
    ( social:db_social(Soc) -> true ; Soc = social{} ),
    findall(RId-Item-Qty, economy:db_market_supply(RId, Item, Qty), Supplies),
    build_market_dict(Supplies, Mkt),
    findall(json{id: QId, npc: Npc, objs: Objs, rews: Rews}, quest_gen:db_generated_quest(Npc, QId, Objs, Rews), GenQuests),
    State = json{
        plyrs: Plyrs,
        mobs: Mobs,
        items: Items,
        rooms: Rooms,
        flags: Fs,
        env: Env,
        social: Soc,
        market: Mkt,
        quests: GenQuests
    }.

build_market_dict(Supplies, Mkt) :-
    findall(RId, member(RId-_-_, Supplies), RIds),
    sort(RId, UniqueRIds),
    build_market_rooms(UniqueRIds, Supplies, Pairs),
    dict_pairs(Mkt, market, Pairs).

build_market_rooms([], _, []).
build_market_rooms([RId|T], Supplies, [RId-SubDict|Rest]) :-
    findall(Item-Qty, member(RId-Item-Qty, Supplies), Items),
    dict_pairs(SubDict, items, Items),
    build_market_rooms(T, Supplies, Rest).

clear_db :-
    retractall(db_entity(_, _, _)),
    retractall(db_node(_, _)),
    retractall(db_flag(_, _)),
    retractall(env:db_env(_)),
    retractall(social:db_social(_)),
    retractall(economy:db_market_supply(_, _, _)),
    retractall(quest_gen:db_generated_quest(_, _, _, _)).
