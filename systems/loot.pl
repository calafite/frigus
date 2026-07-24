:- module(loot, [gen_drops/2]).

:- use_module('../core/world').
:- use_module('../config/spawn').
:- use_module(library(random)).

gen_drops(DeadMob, Evts) :-
    Tag = DeadMob.tag,
    RId = DeadMob.room,
    findall(item{tag: ITag, qty: FinalQty}, (
                spawn_config:loot_table(Tag, ITag, Chance, Min, Max),
                random(F), F =< Chance,
                random_between(Min, Max, FinalQty)
                                            ), Drops),
    spawn_items(RId, Drops, Evts).

spawn_items(_, [], []).
spawn_items(RId, [item{tag: T, qty: Q}|Ts], [dropped(IId, T, Q)|Evts]) :-
    world:gen_id(drop, IId),
    Item = item{id: IId, tag: T, qty: Q, room: RId},
    world:put_entity(Item),
    spawn_items(RId, Ts, Evts).
