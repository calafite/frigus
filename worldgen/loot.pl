:- module(proc_loot, [gen_item/4, gen_chest/3]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module(library(random)).
:- use_module(library(lists)).

roll_tier(T) :-
    random_between(1, 100, R),
    ( R =< 5  -> T = 4
    ; R =< 20 -> T = 3
    ; R =< 50 -> T = 2
    ; T = 1 ).

pick_base(T) :-
    findall(B, world_config:base_wpn(B), W),
    findall(B, world_config:base_arm(B), A),
    findall(B, world_config:base_acc(B), C),
    append([W, A, C], All), random_member(T, All).

gen_item(_Lvl, Tier, Type, Item) :-
    ( Type == none -> pick_base(Base) ; Base = Type ),
    world:gen_id(item, Id),
    Item = item{id: Id, tag: Base, name: Base, tier: Tier, qty: 1}.

gen_chest(Lvl, RId, Items) :-
    random_between(1, 100, R),
    ( R =< 30 ->
          random_between(1, 2, Count),
          findall(I, (between(1, Count, _), roll_tier(T), gen_item(Lvl, T, none, I0), I = I0.put(room, RId)), Items)
    ;
      Items = []
    ).
