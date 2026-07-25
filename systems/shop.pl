:- module(shop, [do_browse/3, do_buy/4, do_sell/4]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/item').
:- use_module('combat').
:- use_module(library(lists)).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

% Determines if a given entity operates as a merchant
is_merchant(Ent) :-
    is_dict(Ent),
    ( get_dict(props, Ent, Props), member(merchant, Props)
    ; get_dict(tag, Ent, merchant)
    ; get_dict(fac, Ent, merchant) ), !.

% Substring & Case-Insensitive Target Matching
match_target(Ent, Query) :-
    get_dict(id, Ent, RawId), to_atom(RawId, Id),
    atom_contains(Id, Query), !.
match_target(Ent, Query) :-
    get_dict(tag, Ent, RawTag), to_atom(RawTag, Tag),
    atom_contains(Tag, Query), !.
match_target(Ent, Query) :-
    get_dict(name, Ent, RawName), to_atom(RawName, Name),
    atom_contains(Name, Query), !.

atom_contains(Full, Sub) :-
    nonvar(Full), nonvar(Sub),
    downcase_atom(Full, FullLower),
    downcase_atom(Sub, SubLower),
    sub_atom(FullLower, _, _, _, SubLower).

% Resolves the NPC query inside the actor's room to a valid merchant
resolve_merchant(Actor, TgtQuery, Merchant) :-
    get_dict(room, Actor, Room),
    world:room_entities(Room, Ents),
    member(Merchant, Ents),
    entity:is_alive(Merchant),
    is_merchant(Merchant),
    match_target(Merchant, TgtQuery), !.

% Calculates dynamic buy/sell rates based on the Actor's Charisma (CHA)
item_prices(Actor, Tag, BuyPrice, SellPrice) :-
    ( item_config:val(Tag, Val) -> true ; Val = 10 ),
    entity:get_stat(Actor, cha, Cha),

    % 1.5% discount per CHA above 10, capped at 1.1x multiplier
    BuyDiscount is (Cha - 10) * 0.015,
    BuyMult is max(1.1, 1.5 - BuyDiscount),

    % 1.0% bonus per CHA above 10, capped at 0.9x multiplier
    SellBonus is (Cha - 10) * 0.01,
    SellMult is min(0.9, 0.5 + SellBonus),

    BuyPrice is max(1, floor(Val * BuyMult)),
    SellPrice is max(1, floor(Val * SellMult)).

% --- Browse Command ---
do_browse(Id, _NpcQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_browse(Id, NpcQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( resolve_merchant(Actor, NpcQuery, Npc) ->
        combat:get_display_name(Npc, NpcName),
        ( get_dict(inv, Npc, Inv) -> true ; Inv = [] ),
        format_inv(Actor, Inv, Formatted),
        Evts = [browse_report(Id, NpcName, Formatted)]
    ;
        Evts = [error(merchant_not_found(NpcQuery))]
    ).

format_inv(_, [], []).
format_inv(Actor, [Item|T], Rest) :-
    is_dict(Item),
    get_dict(tag, Item, RawTag), to_atom(RawTag, Tag),
    Tag == gold, !,
    format_inv(Actor, T, Rest).
format_inv(Actor, [Item|T], [dict{tag: Tag, qty: Qty, price: BuyPrice}|Rest]) :-
    is_dict(Item),
    get_dict(tag, Item, RawTag), to_atom(RawTag, Tag),
    get_dict(qty, Item, Qty),
    item_prices(Actor, Tag, BuyPrice, _), !,
    format_inv(Actor, T, Rest).
format_inv(Actor, [_|T], Rest) :-
    format_inv(Actor, T, Rest).

% --- Buy Command ---
do_buy(_, _, gold, [error(cannot_trade_currency)]) :- !.
do_buy(Id, _NpcQuery, _ItemQuery, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.
do_buy(Id, NpcQuery, ItemQuery, Evts) :-
    world:get_entity(Id, Actor),
    ( resolve_merchant(Actor, NpcQuery, Npc) ->
        ( entity:has_item(Npc, ItemQuery) ->
            to_atom(ItemQuery, Tag),
            item_prices(Actor, Tag, BuyPrice, _),
            ( entity:rem_item(Actor, gold, BuyPrice, A1) ->
                entity:rem_item(Npc, Tag, 1, N1),
                entity:add_item(N1, gold, BuyPrice, N2),
                entity:add_item(A1, Tag, 1, A2),
                world:put_entity(N2),
                world:put_entity(A2),
                combat:get_display_name(Npc, NpcName),
                Evts = [bought(Id, NpcName, Tag, BuyPrice)]
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
            to_atom(ItemQuery, Tag),
            item_prices(Actor, Tag, _, SellPrice),
            ( entity:rem_item(Npc, gold, SellPrice, N1) ->
                entity:rem_item(Actor, Tag, 1, A1),
                entity:add_item(N1, Tag, 1, N2),
                entity:add_item(A1, gold, SellPrice, A2),
                world:put_entity(N2),
                world:put_entity(A2),
                combat:get_display_name(Npc, NpcName),
                Evts = [sold(Id, NpcName, Tag, SellPrice)]
            ;
                Evts = [error(merchant_out_of_gold(NpcQuery, SellPrice))]
            )
        ;
            Evts = [error(item_not_found(Id, ItemQuery))]
        )
    ;
        Evts = [error(merchant_not_found(NpcQuery))]
    ).
