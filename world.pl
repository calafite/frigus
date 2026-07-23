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
    get_dict(id, E, Id),
    retractall(db_entity(Type, Id, _)),
    assertz(db_entity(Type, Id, E)).

update(_, E, db) :-
    get_dict(id, E, Id),
    ( db_entity(Type, Id, _) ->
        retractall(db_entity(Type, Id, _)),
        assertz(db_entity(Type, Id, E))
    ; db_node(Id, _) ->
        retractall(db_node(Id, _)),
        assertz(db_node(Id, E))
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

retag_dict(Dict, NewTag, TaggedDict) :-
    is_dict(Dict), !,
    dict_pairs(Dict, _, Pairs),
    map_retag_pairs(Pairs, CleanPairs),
    dict_pairs(TaggedDict, NewTag, CleanPairs).
retag_dict(List, Tag, CleanList) :-
    is_list(List), !,
    map_retag_list(List, Tag, CleanList).
retag_dict(Val, _, Val).

map_retag_list([], _, []).
map_retag_list([H|T], Tag, [TH|TT]) :-
    retag_dict(H, Tag, TH),
    map_retag_list(T, Tag, TT).

map_retag_pairs([], []).
map_retag_pairs([K-V|T], [K-TV|NT]) :-
    retag_dict(V, dict, TV),
    map_retag_pairs(T, NT).

load_db(RawState) :-
    engine:json_to_term(RawState, State),
    clear_db,
    ( get_dict(plyrs, State, Plyrs) -> forall(member(P0, Plyrs), (retag_dict(P0, plyr, P), get_dict(id, P, PId), assertz(db_entity(plyr, PId, P)))) ; true ),
    ( get_dict(mobs, State, Mobs) -> forall(member(M0, Mobs), (retag_dict(M0, mob, M), get_dict(id, M, MId), assertz(db_entity(mob, MId, M)))) ; true ),
    ( get_dict(items, State, Items) -> forall(member(I0, Items), (retag_dict(I0, item, I), get_dict(id, I, IId), assertz(db_entity(item, IId, I)))) ; true ),
    ( get_dict(rooms, State, Rooms) -> forall(member(R0, Rooms), (retag_dict(R0, room, R), get_dict(id, R, RId), assertz(db_node(RId, R)))) ; true ),
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
    sort(RIds, UniqueRIds),
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
