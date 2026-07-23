% ================================================
:- module(entity, [
    is_alive/1,
    get_stat/3,
    mod_hp/3,
    has_item/2,
    add_item/4,
    rem_item/4
]).

:- use_module(library(lists)).
:- use_module('../config/spawn').

is_alive(Ent) :-
    is_dict(Ent),
    get_dict(hp, Ent, Hp),
    Hp > 0.

get_stat(Ent, Stat, Total) :-
    ( is_dict(Ent), get_dict(Stat, Ent, Base) -> true ; Base = 10 ),
    ( is_dict(Ent), get_dict(race, Ent, Race), catch(spawn_config:race_bonus(Race, Stat, Bonus), _, fail) -> true ; Bonus = 0 ),
    Total is Base + Bonus.
get_stat(_, _, 10).

mod_hp(Ent, Delta, NEnt) :-
    get_dict(hp, Ent, Hp),
    ( get_dict(max_hp, Ent, Max) -> true ; Max = 50 ),
    NHp is max(0, min(Max, Hp + Delta)),
    NEnt = Ent.put(hp, NHp).

has_item(Ent, Tag) :-
    is_dict(Ent),
    get_dict(inv, Ent, Inv),
    member(Stack, Inv),
    is_dict(Stack),
    get_dict(tag, Stack, Tag),
    get_dict(qty, Stack, Qty),
    Qty >= 1, !.

add_item(Ent, Tag, Qty, NEnt) :-
    ( is_dict(Ent), get_dict(inv, Ent, Inv) -> true ; Inv = [] ),
    add_to_inv(Inv, Tag, Qty, NInv),
    NEnt = Ent.put(inv, NInv).

add_to_inv([], Tag, Qty, [stack{tag: Tag, qty: Qty}]).
add_to_inv([Stack|Rest], Tag, Qty, [NStack|Rest]) :-
    is_dict(Stack),
    get_dict(tag, Stack, Tag), !,
    get_dict(qty, Stack, Cur),
    NewQ is Cur + Qty,
    NStack = Stack.put(qty, NewQ).
add_to_inv([Item|Rest], Tag, Qty, [Item|NRest]) :-
    add_to_inv(Rest, Tag, Qty, NRest).

rem_item(Ent, Tag, Qty, NEnt) :-
    ( is_dict(Ent), get_dict(inv, Ent, Inv) -> true ; Inv = [] ),
    rem_from_inv(Inv, Tag, Qty, NInv),
    NEnt = Ent.put(inv, NInv).

rem_from_inv([], _, _, []) :- !.
rem_from_inv([Stack|Rest], Tag, Qty, NInv) :-
    is_dict(Stack),
    get_dict(tag, Stack, Tag),
    get_dict(qty, Stack, Cur),
    Cur >= Qty, !,
    NewQ is Cur - Qty,
    ( NewQ =:= 0 -> NInv = Rest ; NStack = Stack.put(qty, NewQ), NInv = [NStack|Rest] ).
rem_from_inv([Item|Rest], Tag, Qty, [Item|NRest]) :-
    rem_from_inv(Rest, Tag, Qty, NRest).
