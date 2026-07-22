:- module(drop, [gen_drops/5]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

gen_drops(W, A, M, NW, Evts) :-
    room(M, RId),
    Tag = M.tag,
    stat(A, luk, Luk),
    findall(drop(ITag, FinalQty), (
        config:loot_table(Tag, ITag, BaseChance, Min, Max),
        Chance is BaseChance + (Luk * 0.005),
        random(F), F =< Chance,
        random_between(Min, Max, BaseQty),
        FinalQty is BaseQty + floor(Luk * 0.05)
    ), Drops),
    add_drops(W, RId, Drops, W1, DEvts),
    ( get_dict(props, M, Props), \+ member(no_corpse, Props) ->
        id_gen(corpse, CId),
        Corpse = item{id: CId, tag: corpse, mob_tag: Tag, name: "Corpse", qty: 1, room: RId},
        world:add(W1, item, Corpse, NW),
        Evts = [spawned_corpse(CId) | DEvts]
    ;
        NW = W1, Evts = DEvts
    ).

add_drops(W, _, [], W, []).
add_drops(W, RId, [drop(Tag, Qty)|T], NW, [dropped(IId, Tag, Qty)|Evts]) :-
    id_gen(drop, IId),
    Item = item{id: IId, tag: Tag, qty: Qty, room: RId},
    world:add(W, item, Item, TW),
    add_drops(TW, RId, T, NW, Evts).
