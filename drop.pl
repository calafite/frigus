:- module(drop, [gen_drops/4]).

:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).

gen_drops(W, M, NW, Evts) :-
    room(M, RId),
    Tag = M.tag,
    findall(drop(ITag, Qty), (
        config:loot_table(Tag, ITag, Chance, Min, Max),
        random(F), F =< Chance,
        random_between(Min, Max, Qty)
    ), Drops),
    add_drops(W, RId, Drops, NW, Evts).

add_drops(W, _, [], W, []).
add_drops(W, RId, [drop(Tag, Qty)|T], NW, [dropped(IId, Tag, Qty)|Evts]) :-
    random_between(10000, 99999, Rnd),
    format(atom(IId), 'drop_~w', [Rnd]),
    Item = item{id: IId, tag: Tag, qty: Qty, room: RId},
    world:add(W, item, Item, TW),
    add_drops(TW, RId, T, NW, Evts).
