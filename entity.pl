:- module(entity, [
    hp/2, hp/3, room/2, room/3, mp/2, mp/3,
    lvl/2, lvl/3, inv/2, inv/3, equip/2, equip/3,
    fac/2, fac/3, wpn/2, alive/1,
    inv_add/4, inv_rem/4, inv_wt/2, max_wt/2
]).

:- use_module(config).

hp(E, E.hp).         hp(E, V, E.put(hp, V)).
room(E, E.room).     room(E, V, E.put(room, V)).
mp(E, E.mp).         mp(E, V, E.put(mp, V)).
lvl(E, E.lvl).       lvl(E, V, E.put(lvl, V)).
inv(E, E.inv).       inv(E, V, E.put(inv, V)).
equip(E, E.equip).   equip(E, V, E.put(equip, V)).
fac(E, E.fac).       fac(E, V, E.put(fac, V)).

wpn(E, W) :- is_dict(E, plyr), get_dict(wpn, E.equip, W), W \== none, !.
wpn(_, fists).

alive(E) :- hp(E, Hp), Hp > 0.

inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: NQ} | R]) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R), !, NQ is OQ + Qty.
inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: Qty} | Inv]).

inv_rem(Inv, Tag, Qty, NInv) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R),
    OQ >= Qty,
    NQ is OQ - Qty,
    ( NQ =:= 0 -> NInv = R ; NInv = [stack{tag: Tag, qty: NQ} | R] ).

inv_wt([], 0).
inv_wt([stack{tag: Tag, qty: Q} | T], W) :-
    config:weight(Tag, UW),
    inv_wt(T, RW),
    W is RW + (UW * Q).

max_wt(_E, 50).
