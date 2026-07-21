:- module(entity, [
    hp/2, hp/3, room/2, room/3, mp/2, mp/3,
    lvl/2, lvl/3, inv/2, inv/3, equip/2, equip/3,
    wpn/2, alive/1
]).

hp(E, E.hp).         hp(E, V, E.put(hp, V)).
room(E, E.room).     room(E, V, E.put(room, V)).
mp(E, E.mp).         mp(E, V, E.put(mp, V)).
lvl(E, E.lvl).       lvl(E, V, E.put(lvl, V)).
inv(E, E.inv).       inv(E, V, E.put(inv, V)).
equip(E, E.equip).   equip(E, V, E.put(equip, V)).

wpn(E, W) :- is_dict(E, plyr), get_dict(wpn, E.equip, W), W \== none, !.
wpn(_, fists).

alive(E) :- hp(E, Hp), Hp > 0.
