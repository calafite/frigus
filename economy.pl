:- module(economy, [
    db_market_supply/3,
    item_price/5,
    mod_supply/4,
    tick_economy/3
]).

:- use_module(config).
:- use_module(world).
:- use_module(library(random)).
:- use_module(library(lists)).

:- dynamic db_market_supply/3.

baseline_supply(timber, 50).
baseline_supply(iron_ore, 30).
baseline_supply(gold_ore, 10).
baseline_supply(coal, 40).
baseline_supply(bread, 25).
baseline_supply(cooked_fish, 20).
baseline_supply(cooked_meat, 20).
baseline_supply(potion, 15).
baseline_supply(empty_waterskin, 30).
baseline_supply(filled_waterskin, 15).
baseline_supply(sword, 5).
baseline_supply(plate_mail, 2).
baseline_supply(_, 10).

item_price(RId, ItemTag, buy, A, Price) :-
    get_supply(RId, ItemTag, Sup),
    baseline_supply(ItemTag, Base),
    config:val(ItemTag, BasePrice),
    entity:stat(A, cha, Cha), entity:stat(A, luk, Luk),
    Factor is Base / max(1, Sup),
    RawPrice is BasePrice * Factor,
    Discount is (Cha * 0.01) + (Luk * 0.005),
    Price is max(1, floor(RawPrice * (1.2 - Discount))).

item_price(RId, ItemTag, sell, A, Price) :-
    get_supply(RId, ItemTag, Sup),
    baseline_supply(ItemTag, Base),
    config:val(ItemTag, BasePrice),
    entity:stat(A, cha, Cha), entity:stat(A, luk, Luk),
    Factor is Base / max(1, Sup),
    RawPrice is BasePrice * Factor,
    Bonus is (Cha * 0.01) + (Luk * 0.005),
    Price is max(1, floor(RawPrice * (0.6 + Bonus))).

get_supply(RId, ItemTag, Sup) :-
    db_market_supply(RId, ItemTag, Sup), !.
get_supply(RId, ItemTag, Base) :-
    baseline_supply(ItemTag, Base),
    assertz(db_market_supply(RId, ItemTag, Base)).

mod_supply(RId, ItemTag, Delta, NSup) :-
    get_supply(RId, ItemTag, Cur),
    NSup is max(0, Cur + Delta),
    retractall(db_market_supply(RId, ItemTag, _)),
    assertz(db_market_supply(RId, ItemTag, NSup)).

tick_economy(_, db, Evts) :-
    findall(RId-Item-Sup, db_market_supply(RId, Item, Sup), Supps),
    decay_supplies(Supps, Evts).

decay_supplies([], []).
decay_supplies([RId-Item-Sup|T], Evts) :-
    baseline_supply(Item, Base),
    ( Sup < Base ->
        NSup is Sup + 1,
        retractall(db_market_supply(RId, Item, _)),
        assertz(db_market_supply(RId, Item, NSup)),
        Evt = [market_replenished(RId, Item)]
    ; Sup > Base ->
        NSup is Sup - 1,
        retractall(db_market_supply(RId, Item, _)),
        assertz(db_market_supply(RId, Item, NSup)),
        Evt = [market_stabilized(RId, Item)]
    ;
        Evt = []
    ),
    decay_supplies(T, REvts),
    append(Evt, REvts, Evts).
