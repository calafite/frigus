:- module(npc, [step_talk/5, step_buy/7, step_sell/7, step_steal/7]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).

step_talk(W, AId, TId, W, [say(TId, Msg)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    get_dict(dialogue, T, Msg).

step_buy(W, AId, TId, Tag, Qty, NW, [bought(AId, Tag, Qty, Cost)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    member(merchant, T.props),
    config:val(Tag, Val),
    Cost is Val * Qty,
    inv(A, AInv),
    inv(T, TInv),
    inv_rem(TInv, Tag, Qty, TInv1),
    inv_add(TInv1, gold, Cost, NTInv),
    inv_rem(AInv, gold, Cost, AInv1),
    inv_add(AInv1, Tag, Qty, NAInv),
    inv(A, NAInv, NA),
    inv(T, NTInv, NT),
    world:update(W, NT, W1),
    world:update(W1, NA, NW).

step_sell(W, AId, TId, Tag, Qty, NW, [sold(AId, Tag, Qty, Earned)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    member(merchant, T.props),
    config:val(Tag, Val),
    Earned is floor(Val * Qty * 0.5),
    inv(A, AInv),
    inv(T, TInv),
    inv_rem(TInv, gold, Earned, TInv1),
    inv_add(TInv1, Tag, Qty, NTInv),
    inv_rem(AInv, Tag, Qty, AInv1),
    inv_add(AInv1, gold, Earned, NAInv),
    inv(A, NAInv, NA),
    inv(T, NTInv, NT),
    world:update(W, NT, W1),
    world:update(W1, NA, NW).

roll_steal(A, T) :-
    stat(A, dex, Dex),
    stat(T, int, Int),
    random_between(1, 20, Roll),
    Roll + Dex >= 10 + Int.

step_steal(W, AId, TId, Tag, Qty, NW, Evts) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    inv(T, TInv),
    inv_rem(TInv, Tag, Qty, NTInv),
    ( roll_steal(A, T) ->
        inv(A, AInv),
        inv_add(AInv, Tag, Qty, NAInv),
        inv(A, NAInv, NA),
        inv(T, NTInv, NT),
        world:update(W, NT, W1),
        world:update(W1, NA, NW),
        Evts = [stole(AId, TId, Tag, Qty)]
    ;
        fac(A, criminal, NA),
        world:update(W, NA, NW),
        Evts = [caught(AId, TId), fac_change(AId, criminal)]
    ).
