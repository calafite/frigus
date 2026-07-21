:- module(ai, [step_ai/4]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(move).
:- use_module(combat).

step_ai(W, Id, NW, Evts) :- ai_flee(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_attack(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_chase(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_patrol(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_wander(W, Id, NW, Evts), !.
step_ai(W, _, W, []).

ai_flee(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    hp(M, Hp), get_dict(max_hp, M, MaxHp),
    Hp < MaxHp * 0.2,
    room(M, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits),
    Exits \= [],
    random_member(Dir, Exits),
    step_move(W, Id, Dir, NW, Evts).

ai_attack(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    room(M, RId),
    world:room_entities(W, RId, Ents),
    member(T, Ents),
    alive(T),
    fac(M, F1), fac(T, F2),
    config:enemy(F1, F2),
    combat:valid_target(W, M, T),
    !,
    step_kill(W, Id, T.id, NW, Evts).

ai_chase(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    room(M, RId), world:node(W, RId, N),
    get_dict(Dir, N.exits, NRId),
    world:room_entities(W, NRId, Ents),
    member(T, Ents), alive(T),
    fac(M, F1), fac(T, F2), config:enemy(F1, F2),
    !,
    step_move(W, Id, Dir, NW, Evts).

ai_patrol(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    get_dict(route, M, Route),
    get_dict(route_idx, M, Idx),
    length(Route, Len),
    NIdx is (Idx + 1) mod Len,
    nth0(NIdx, Route, NRId),
    room(M, RId), world:node(W, RId, N),
    get_dict(Dir, N.exits, NRId),
    NM = M.put(route_idx, NIdx),
    world:update(W, NM, TW),
    step_move(TW, Id, Dir, NW, Evts).

ai_wander(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    get_dict(wander, M, true),
    room(M, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits),
    Exits \= [],
    random_member(Dir, Exits),
    step_move(W, Id, Dir, NW, Evts).
