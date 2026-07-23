:- module(build, [step_build/5, step_demolish/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_build).
:- use_module(status).
:- use_module(craft).

step_build(W, Id, StructTag, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; \+ cfg_build:struct_data(StructTag, _, _, _) ->
        NW = W, Evts = [unknown_structure(Id, StructTag)]
    ;
        cfg_build:struct_data(StructTag, Cost, Type, Prop),
        inv(A, Inv),
        ( craft:check_ingredients(Inv, Cost) ->
            craft:consume_ingredients(Inv, Cost, NInv),
            room(A, RId), world:node(W, RId, N),
            ( get_dict(props, N, Props) -> true ; Props = [] ),
            ( Type == obstacle -> NN = N.put(props, [Prop|Props])
            ; Type == prop -> NN = N.put(props, [Prop|Props])
            ; Type == door ->
                ( get_dict(exits, N, Exits), dict_keys(Exits, [Dir|_]) -> true ; Dir = north ),
                ( get_dict(locked_exits, N, Ls) -> true ; Ls = [] ),
                NN = N.put(locked_exits, [Dir|Ls])
            ; Type == container ->
                random_between(100000, 999999, Rnd), atomic_list_concat([chest_, Rnd], CId),
                ( get_dict(furniture, N, Furns) -> true ; Furns = dict{} ),
                NFurns = Furns.put(CId, dict{type: chest, user: none, inventory: []}),
                NN = N.put(furniture, NFurns)
            ),
            world:update(W, A.put(inv, NInv), W1),
            world:update(W1, NN, NW),
            Evts = [built_structure(Id, StructTag, RId)]
        ;
            NW = W, Evts = [missing_materials(Id, StructTag)]
        )
    ).

step_demolish(W, Id, Prop, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; inv(A, Inv), \+ (member(stack{tag: sledgehammer, qty: Q}, Inv), Q >= 1), \+ (member(I, Inv), is_dict(I, item), I.tag == sledgehammer) ->
        NW = W, Evts = [missing_tool(Id, sledgehammer)]
    ; room(A, RId), world:node(W, RId, N), get_dict(props, N, Props), member(Prop, Props) ->
        select(Prop, Props, Rest),
        NN = N.put(props, Rest),
        world:update(W, NN, NW),
        Evts = [demolished(Id, Prop, RId)]
    ;
        NW = W, Evts = [prop_not_found(Id, Prop)]
    ).
