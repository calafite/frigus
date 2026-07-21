:- module(npc, [step_talk/5, step_buy/6, step_sell/6]).

:- use_module(config).
:- use_module(entity).
:- use_module(world).

step_talk(W, AId, TId, NW, [say(TId, Msg)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    get_dict(dialogue, T, Msg),
    NW = W.

step_buy(W, AId, TId, Tag, Qty, NW, [bought(AId, Tag, Qty, Cost)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    member(merchant, T.props),
    config:val(Tag, Val),
    Cost is Val * Qty,
    inv(A, Inv),
    inv_rem(Inv, gold, Cost, MidInv),
    inv_add(MidInv, Tag, Qty, NInv),
    inv(A, NInv, NA),
    world:update(W, NA, NW).

step_sell(W, AId, TId, Tag, Qty, NW, [sold(AId, Tag, Qty, Earned)]) :-
    world:entity(W, AId, A),
    world:entity(W, TId, T),
    room(A, RId),
    room(T, RId),
    member(merchant, T.props),
    config:val(Tag, Val),
    Earned is floor(Val * Qty * 0.5),
    inv(A, Inv),
    inv_rem(Inv, Tag, Qty, MidInv),
    inv_add(MidInv, gold, Earned, NInv),
    inv(A, NInv, NA),
    world:update(W, NA, NW).
