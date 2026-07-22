:- module(npc, [step_talk/5, step_buy/7, step_sell/7, step_steal/7]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(quest).
:- use_module(npc_life).
:- use_module(economy).

step_talk(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A), world:entity(W, TId, T),
    room(A, RId), room(T, RId),
    quest:update_talk(A, T.tag, NA, QEvts),
    fac(T, TFac), rep_val(NA, TFac, Rep), get_dict(dialogue, T, Dial),
    ( Rep =< -20 -> get_dict(hostile, Dial, Msg)
    ; Rep >= 20  -> get_dict(friendly, Dial, Msg)
    ; get_dict(neutral, Dial, Msg) ), !,
    world:update(W, NA, W1),
    npc_life:mod_mem(W1, TId, AId, talk, NW),
    Evts = [say(TId, Msg) | QEvts].

step_talk(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A), world:entity(W, TId, T),
    room(A, RId), room(T, RId),
    quest:update_talk(A, T.tag, NA, QEvts),
    get_dict(dialogue, T, Msg),
    world:update(W, NA, W1),
    npc_life:mod_mem(W1, TId, AId, talk, NW),
    Evts = [say(TId, Msg) | QEvts].

step_buy(W, AId, TId, Tag, Qty, NW, [bought(AId, Tag, Qty, Cost)]) :-
    world:entity(W, AId, A), world:entity(W, TId, T), room(A, RId), room(T, RId),
    member(merchant, T.props), fac(T, TFac), rep_val(A, TFac, Rep),
    economy:item_price(RId, Tag, buy, A, BaseCost),
    Cost is BaseCost * Qty,
    inv(A, AInv), inv(T, TInv), inv_rem(TInv, Tag, Qty, TInv1), inv_add(TInv1, gold, Cost, NTInv),
    inv_rem(AInv, gold, Cost, AInv1), inv_add(AInv1, Tag, Qty, NAInv),
    rep_mod(A, TFac, 1, NA1), inv(NA1, NAInv, NA), inv(T, NTInv, NT),
    economy:mod_supply(RId, Tag, -Qty, _),
    world:update(W, NT, W1), world:update(W1, NA, W2),
    npc_life:mod_mem(W2, TId, AId, trade, NW).

step_sell(W, AId, TId, Tag, Qty, NW, [sold(AId, Tag, Qty, Earned)]) :-
    world:entity(W, AId, A), world:entity(W, TId, T), room(A, RId), room(T, RId),
    member(merchant, T.props), fac(T, TFac), rep_val(A, TFac, Rep),
    economy:item_price(RId, Tag, sell, A, BaseEarned),
    Earned is BaseEarned * Qty,
    inv(A, AInv), inv(T, TInv), inv_rem(TInv, gold, Earned, TInv1), inv_add(TInv1, Tag, Qty, NTInv),
    inv_rem(AInv, Tag, Qty, AInv1), inv_add(AInv1, gold, Earned, NAInv),
    rep_mod(A, TFac, 1, NA1), inv(NA1, NAInv, NA), inv(T, NTInv, NT),
    economy:mod_supply(RId, Tag, Qty, _),
    world:update(W, NT, W1), world:update(W1, NA, W2),
    npc_life:mod_mem(W2, TId, AId, trade, NW).

roll_steal(A, T, Tag, Qty) :-
    stat(A, dex, Dex), stat(A, luk, Luk),
    stat(T, wis, Wis), stat(T, int, Int),
    config:val(Tag, Val), config:rarity(Tag, Rar),
    random_between(1, 20, Roll), Target is 10 + floor(Wis * 0.6) + floor(Int * 0.4) + floor((Val * Qty) / 10) + (Rar * 5),
    Roll + Dex + floor(Luk * 0.5) >= Target.

step_steal(W, AId, TId, Tag, Qty, NW, Evts) :-
    world:entity(W, AId, A), world:entity(W, TId, T), room(A, RId), room(T, RId),
    inv(T, TInv), inv_rem(TInv, Tag, Qty, NTInv), fac(T, TFac),
    ( roll_steal(A, T, Tag, Qty) ->
        inv(A, AInv), inv_add(AInv, Tag, Qty, NAInv), rep_mod(A, TFac, -5, NA1),
        inv(NA1, NAInv, NA), inv(T, NTInv, NT),
        world:update(W, NT, W1), world:update(W1, NA, NW), Evts = [stole(AId, TId, Tag, Qty)]
    ; fac(A, criminal, A1), rep_mod(A1, TFac, -20, NA),
      world:update(W, NA, W1), npc_life:mod_mem(W1, TId, AId, steal, NW),
      Evts = [caught(AId, TId), fac_change(AId, criminal)] ).
