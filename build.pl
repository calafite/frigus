:- module(build, [step_build/5, step_demolish/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_build).
:- use_module(status).
:- use_module(zone).
:- use_module(craft).

step_build(W, Id, StructTag, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    cfg_build:struct_data(StructTag, Cost, Type, Prop),
    inv(A, Inv), craft:check_ingredients(Inv, Cost),
    craft:consume_ingredients(Inv, Cost, NInv),
    room(A, RId), world:node(W, RId, N),
    ( Type == obstacle -> NN = N.put(props, [Prop|N.props])
    ; Type == prop -> NN = N.put(props, [Prop|N.props])
    ; Type == door -> get_dict(exits, N, Exits), dict_keys(Exits, [Dir|_]), NN = N.put(locked_exits, [Dir|N.locked_exits])
    ; Type == container ->
        random_between(100000, 999999, Rnd), atomic_list_concat([chest_, Rnd], CId),
        get_dict(furniture, N, Furns),
        NFurns = Furns.put(CId, dict{type: chest, user: none, inventory: []}),
        NN = N.put(furniture, NFurns)
    ),
    world:update(W, A.put(inv, NInv), W1),
    zone:update_room(W1, NN, NW),
    Evts = [built_structure(Id, StructTag, RId)].

step_demolish(W, Id, Prop, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), member(stack{tag: sledgehammer, qty: _}, Inv),
    room(A, RId), world:node(W, RId, N),
    member(Prop, N.props),
    select(Prop, N.props, Rest),
    NN = N.put(props, Rest),
    zone:update_room(W, NN, NW),
    Evts = [demolished(Id, Prop, RId)].
