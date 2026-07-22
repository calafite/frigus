:- module(proc_loot, [gen_item/4, gen_chest/3]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(cfg_proc_loot).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

roll_tier(T) :-
    random_between(1, 100, R),
    ( R =< 2  -> T = 5
    ; R =< 8  -> T = 4
    ; R =< 25 -> T = 3
    ; R =< 60 -> T = 2
    ; T = 1 ).

pick_base(T) :-
    findall(B, cfg_proc_loot:base_wpn(B), W),
    findall(B, cfg_proc_loot:base_arm(B), A),
    findall(B, cfg_proc_loot:base_acc(B), C),
    append([W, A, C], All), random_member(T, All).

gen_item(Lvl, Tier, Type, Item) :-
    ( Type == none -> pick_base(Base) ; Base = Type ),
    cfg_proc_loot:tier_mult(Tier, Mult),
    id_gen(item, Id),
    ( Tier >= 2 -> findall(P, cfg_proc_loot:pref(P, _, _, _), Ps), random_member(Pref, Ps) ; Pref = none ),
    ( Tier >= 3 -> findall(S, cfg_proc_loot:suff(S, _, _, _), Ss), random_member(Suff, Ss) ; Suff = none ),
    build_name(Pref, Base, Suff, Name),
    ( Tier >= 3 ->
        random_between(1, 100, SockRoll),
        ( SockRoll <= 15 -> SockProp = [prop(sockets, 2)]
        ; SockRoll <= 45 -> SockProp = [prop(sockets, 1)]
        ; SockProp = [] )
    ; SockProp = [] ),
    build_props(Pref, Suff, Lvl, Mult, BaseProps),
    append(SockProp, BaseProps, Props),
    Item = item{id: Id, tag: Base, name: Name, tier: Tier, qty: 1, props: Props}.

build_name(none, Base, none, Base).
build_name(Pref, Base, none, Name) :- atomic_list_concat([Pref, Base], ' ', Name).
build_name(none, Base, Suff, Name) :- atomic_list_concat([Base, 'of the', Suff], ' ', Name).
build_name(Pref, Base, Suff, Name) :- atomic_list_concat([Pref, Base, 'of the', Suff], ' ', Name).

build_props(Pref, Suff, Lvl, Mult, Props) :-
    apply_prop(Pref, Lvl, Mult, P1),
    apply_prop(Suff, Lvl, Mult, P2),
    append(P1, P2, Props).

apply_prop(none, _, _, []).
apply_prop(A, Lvl, Mult, [prop(Stat, Val)]) :-
    ( cfg_proc_loot:pref(A, Stat, Min, Max) ; cfg_proc_loot:suff(A, Stat, Min, Max) ), !,
    random_between(Min, Max, BaseVal),
    Val is floor(BaseVal * (1 + (Lvl * 0.1)) * Mult).

gen_chest(Lvl, RId, Items) :-
    random_between(1, 100, R),
    ( R =< 40 ->
        random_between(1, 3, Count),
        findall(I, (between(1, Count, _), roll_tier(T), gen_item(Lvl, T, none, I0), I = I0.put(room, RId)), Items)
    ;
        Items = []
    ).
