:- module(npc, [step_talk/5, step_buy/7, step_sell/7, step_steal/7]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(quest).
:- use_module(npc_life).
:- use_module(economy).
:- use_module(combat).

get_npc_dialogue(T, A, Msg) :-
    get_dict(dialogue, T, Dial),
    is_dict(Dial), !,
    fac(T, TFac), rep_val(A, TFac, Rep),
    ( Rep =< -20, get_dict(hostile, Dial, M) -> Msg = M
    ; Rep >= 20, get_dict(friendly, Dial, M) -> Msg = M
    ; get_dict(neutral, Dial, M) -> Msg = M
    ; Msg = "Greetings, traveler." ).
get_npc_dialogue(T, _, Msg) :-
    get_dict(dialogue, T, Msg), string(Msg), !.
get_npc_dialogue(T, _, Msg) :-
    get_dict(name, T, Name),
    atomic_list_concat([Name, " nods at you."], "", Msg), !.
get_npc_dialogue(_, _, "Greetings, traveler.").

step_talk(W, AId, TQuery, NW, Evts) :-
    world:entity(W, AId, A),
    room(A, RId),
    ( combat:resolve_target(W, AId, RId, TQuery, T) ->
        quest:update_talk(A, T.tag, NA, QEvts),
        get_npc_dialogue(T, NA, Msg),
        world:update(W, NA, W1),
        npc_life:mod_mem(W1, T.id, AId, talk, NW),
        Evts = [say(T.id, Msg) | QEvts]
    ;
        NW = W, Evts = [target_not_found(AId, TQuery)]
    ).

step_buy(W, AId, TQuery, Tag, Qty, NW, Evts) :-
    world:entity(W, AId, A), room(A, RId),
    ( combat:resolve_target(W, AId, RId, TQuery, T) ->
        ( props(T, Props), member(merchant, Props) ->
            inv(T, TInv),
            ( inv_rem(TInv, Tag, Qty, TInv1) ->
                economy:item_price(RId, Tag, buy, A, BaseCost),
                Cost is BaseCost * Qty,
                inv(A, AInv),
                ( inv_rem(AInv, gold, Cost, AInv1) ->
                    inv_add(TInv1, gold, Cost, NTInv),
                    inv_add(AInv1, Tag, Qty, NAInv),
                    fac(T, TFac), rep_mod(A, TFac, 1, NA1),
                    inv(NA1, NAInv, NA), inv(T, NTInv, NT),
                    economy:mod_supply(RId, Tag, -Qty, _),
                    world:update(W, NT, W1), world:update(W1, NA, W2),
                    npc_life:mod_mem(W2, T.id, AId, trade, NW),
                    Evts = [bought(AId, Tag, Qty, Cost)]
                ;
                    NW = W, Evts = [insufficient_gold(AId, Cost)]
                )
            ;
                NW = W, Evts = [out_of_stock(T.id, Tag)]
            )
        ;
            NW = W, Evts = [not_a_merchant(T.id)]
        )
    ;
        NW = W, Evts = [target_not_found(AId, TQuery)]
    ).

step_sell(W, AId, TQuery, Tag, Qty, NW, Evts) :-
    world:entity(W, AId, A), room(A, RId),
    ( combat:resolve_target(W, AId, RId, TQuery, T) ->
        ( props(T, Props), member(merchant, Props) ->
            inv(A, AInv),
            ( inv_rem(AInv, Tag, Qty, AInv1) ->
                economy:item_price(RId, Tag, sell, A, BaseEarned),
                Earned is BaseEarned * Qty,
                inv(T, TInv),
                ( inv_rem(TInv, gold, Earned, TInv1) ->
                    inv_add(TInv1, Tag, Qty, NTInv),
                    inv_add(AInv1, gold, Earned, NAInv),
                    fac(T, TFac), rep_mod(A, TFac, 1, NA1),
                    inv(NA1, NAInv, NA), inv(T, NTInv, NT),
                    economy:mod_supply(RId, Tag, Qty, _),
                    world:update(W, NT, W1), world:update(W1, NA, W2),
                    npc_life:mod_mem(W2, T.id, AId, trade, NW),
                    Evts = [sold(AId, Tag, Qty, Earned)]
                ;
                    NW = W, Evts = [merchant_out_of_gold(T.id)]
                )
            ;
                NW = W, Evts = [item_not_in_inv(AId, Tag)]
            )
        ;
            NW = W, Evts = [not_a_merchant(T.id)]
        )
    ;
        NW = W, Evts = [target_not_found(AId, TQuery)]
    ).

roll_steal(A, T, Tag, Qty) :-
    stat(A, dex, Dex), stat(A, luk, Luk),
    stat(T, wis, Wis), stat(T, int, Int),
    config:val(Tag, Val), config:rarity(Tag, Rar),
    random_between(1, 20, Roll), Target is 10 + floor(Wis * 0.6) + floor(Int * 0.4) + floor((Val * Qty) / 10) + (Rar * 5),
    Roll + Dex + floor(Luk * 0.5) >= Target.

step_steal(W, AId, TQuery, Tag, Qty, NW, Evts) :-
    world:entity(W, AId, A), room(A, RId),
    ( combat:resolve_target(W, AId, RId, TQuery, T) ->
        inv(T, TInv),
        ( inv_rem(TInv, Tag, Qty, NTInv) ->
            fac(T, TFac),
            ( roll_steal(A, T, Tag, Qty) ->
                inv(A, AInv), inv_add(AInv, Tag, Qty, NAInv), rep_mod(A, TFac, -5, NA1),
                inv(NA1, NAInv, NA), inv(T, NTInv, NT),
                world:update(W, NT, W1), world:update(W1, NA, NW), Evts = [stole(AId, T.id, Tag, Qty)]
            ;
                fac(A, criminal, A1), rep_mod(A1, TFac, -20, NA),
                world:update(W, NA, W1), npc_life:mod_mem(W1, T.id, AId, steal, NW),
                Evts = [caught(AId, T.id), fac_change(AId, criminal)]
            )
        ;
            NW = W, Evts = [target_does_not_have_item(T.id, Tag)]
        )
    ;
        NW = W, Evts = [target_not_found(AId, TQuery)]
    ).
