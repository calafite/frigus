:- module(ritual, [step_ritual/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(craft).
:- use_module(env).
:- use_module(zone).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

step_ritual(W, Id, Type, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    room(A, RId), world:node(W, RId, N),
    member(ritual_circle, N.props),
    ritual_reqs(Type, Items),
    inv(A, Inv), craft:check_ingredients(Inv, Items),
    craft:consume_ingredients(Inv, Items, NInv),
    A1 = A.put(inv, NInv),
    world:update(W, A1, W1),
    execute_ritual(Type, W1, Id, RId, N, NW, RitualEvts),
    Evts = [ritual_complete(Id, Type) | RitualEvts].

ritual_reqs(summon_dragon, [stack{tag: dragon_scale, qty: 3}, stack{tag: sunstone, qty: 1}, stack{tag: fire_lily, qty: 3}]).
ritual_reqs(consecration, [stack{tag: holy_water, qty: 3}, stack{tag: sunstone, qty: 1}, stack{tag: elixir_of_life, qty: 1}]).
ritual_reqs(planar_rift, [stack{tag: shadow_essence, qty: 3}, stack{tag: deadly_poison, qty: 2}]).
ritual_reqs(weather_storm, [stack{tag: griffin_feather, qty: 3}, stack{tag: electrum_ingot, qty: 1}]).

execute_ritual(summon_dragon, W, _, RId, _, NW, [spawned_dragon(DragId)]) :-
    id_gen(mob, DragId),
    Lvl = 50, BaseHp is 500, BaseStr is 40, BaseDex is 30, BaseInt is 30,
    Dragon = mob{id: DragId, tag: dragon, name: "Legendary Fire Dragon", lvl: Lvl, hp: BaseHp, max_hp: BaseHp, str: BaseStr, dex: BaseDex, int: BaseInt, room: RId, props: [boss, fire_immune], threats: dict{}},
    world:add(W, mob, Dragon, NW).

execute_ritual(consecration, W, _, RId, N, NW, [room_consecrated(RId)]) :-
    findall(P, (member(P, N.props), \+ member(P, [dark, burning(_), poison])), CleanProps),
    NN = N.put(props, [safe, holy | CleanProps]),
    zone:update_room(W, NN, NW).

execute_ritual(planar_rift, W, _, RId, N, NW, [rift_opened(RId, void_prison)]) :-
    ensure_void_prison(W, W1),
    NN = N.put(exits, N.exits.put(rift, void_prison)),
    zone:update_room(W1, NN, NW).

execute_ritual(weather_storm, W, _, _, _, NW, [storm_called]) :-
    env:db_env(Env),
    NEnv = Env.put(weath, storm),
    retractall(env:db_env(_)), assertz(env:db_env(NEnv)),
    NW = W.

ensure_void_prison(W, NW) :-
    ( world:db_node(void_prison, _) -> NW = W
    ;
        VoidRoom = dict{id: void_prison, theme: void, type: normal, desc: "A silent, endless void of absolute nothingness. There is no escape.", exits: dict{}, props: [dark, silent, cold_immune], lvl: 50},
        world:add(W, room, VoidRoom, NW)
    ).
