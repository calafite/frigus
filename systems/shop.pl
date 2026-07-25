:- module(shop, [do_browse/3, do_buy/4, do_sell/4]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/item').
:- use_module('combat').
:- use_module(library(lists)).

% Determines if a given entity operates as a merchant
is_merchant(Ent) :-
    is_dict(Ent),
    ( get_dict(props, Ent, Props), member(merchant, Props)
    ; get_dict(tag, Ent, merchant)
    ; get_dict(fac, Ent, merchant) ), !.

% Resolves the NPC query inside the actor's room to a valid merchant
resolve_merchant(Actor, TgtQuery, Merchant) :-
    get_dict(room, Actor, Room),
    world:room_entities(Room, Ents),
    member(Merchant, Ents),
    ( get_dict(id, Merchant, TgtQuery) ; get_dict(tag, Merchant, TgtQuery) ),
    entity:is_alive(Merchant),
    is_merchant(Merchant), !.

% Calculates fixed buy/sell rates for the realm based on item value
item_prices(Tag, BuyPrice, SellPrice) :-
    ( item_config:val(Tag, Val) -> true ; Val = 10 ),
    BuyPrice is max(1, floor(Val * 1.5)),
    SellPrice is max(1, floor(Val * 0.5)).

% --- Browse Command ---
do_browse(Id, _NpcQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_browse(Id, NpcQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( resolve_merchant(Actor, NpcQuery, Npc) ->
          combat:get_display_name(Npc, NpcName),
          ( get_dict(inv, Npc, Inv) -> true ; Inv = [] ),
          format_inv(Inv, Formatted),
          Evts = [browse_report(Id, NpcName, Formatted)]
    ;
      Evts = [error(merchant_not_found(NpcQuery))]
    ).

format_inv([], []).
format_inv([stack{tag: gold, qty: _}|T], Rest) :- !, format_inv(T, Rest).
format_inv([stack{tag: Tag, qty: Qty}|T], [dict{tag: Tag, qty: Qty, price: BuyPrice}|Rest]) :-
    item_prices(Tag, BuyPrice, _),
    format_inv(T, Rest).

% --- Buy Command ---
do_buy(_, _, gold, [error(cannot_trade_currency)]) :- !.
do_buy(Id, _NpcQuery, _ItemQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_buy(Id, NpcQuery, ItemQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( resolve_merchant(Actor, NpcQuery, Npc) ->
          ( entity:has_item(Npc, ItemQuery) ->
                item_prices(ItemQuery, BuyPrice, _),
                ( entity:rem_item(Actor, gold, BuyPrice, A1) ->
                      entity:rem_item(Npc, ItemQuery, 1, N1),
                      entity:add_item(N1, gold, BuyPrice, N2),
                      entity:add_item(A1, ItemQuery, 1, A2),
                      world:put_entity(N2),
                      world:put_entity(A2),
                      combat:get_display_name(Npc, NpcName),
                      Evts = [bought(Id, NpcName, ItemQuery, BuyPrice)]
                ;
                  Evts = [error(insufficient_gold(Id, BuyPrice))]
                )
          ;
            Evts = [error(merchant_out_of_stock(NpcQuery, ItemQuery))]
          )
    ;
      Evts = [error(merchant_not_found(NpcQuery))]
    ).

% --- Sell Command ---
do_sell(_, _, gold, [error(cannot_trade_currency)]) :- !.
do_sell(Id, _NpcQuery, _ItemQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_sell(Id, NpcQuery, ItemQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( resolve_merchant(Actor, NpcQuery, Npc) ->
          ( entity:has_item(Actor, ItemQuery) ->
                item_prices(ItemQuery, _, SellPrice),
                ( entity:rem_item(Npc, gold, SellPrice, N1) ->
                      entity:rem_item(Actor, ItemQuery, 1, A1),
                      entity:add_item(N1, ItemQuery, 1, N2),
                      entity:add_item(A1, gold, SellPrice, A2),
                      world:put_entity(N2),
                      world:put_entity(A2),
                      combat:get_display_name(Npc, NpcName),
                      Evts = [sold(Id, NpcName, ItemQuery, SellPrice)]
                ;
                  Evts = [error(merchant_out_of_gold(NpcQuery, SellPrice))]
                )
          ;
            Evts = [error(item_not_found(Id, ItemQuery))]
          )
    ;
      Evts = [error(merchant_not_found(NpcQuery))]
    ).
