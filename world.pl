:- module(world, [
    entity/3, node/3, add/4,
    update/3, remove/3, room_entities/3
]).

entity(W, Id, E) :- member(E, W.plyrs), E.id == Id, !.
entity(W, Id, E) :- member(E, W.mobs),  E.id == Id, !.
entity(W, Id, E) :- member(E, W.items), E.id == Id, !.

node(W, Id, N) :- member(N, W.rooms), N.id == Id, !.

add(W, plyr, E, W.put(plyrs, [E|W.plyrs])).
add(W, mob, E, W.put(mobs, [E|W.mobs])).
add(W, item, E, W.put(items, [E|W.items])).

update(W, E, NW) :- select(O, W.plyrs, R), O.id == E.id, !, NW = W.put(plyrs, [E|R]).
update(W, E, NW) :- select(O, W.mobs, R),  O.id == E.id, !, NW = W.put(mobs, [E|R]).
update(W, E, NW) :- select(O, W.items, R), O.id == E.id, !, NW = W.put(items, [E|R]).

remove(W, Id, NW) :- select(O, W.mobs, R),  O.id == Id, !, NW = W.put(mobs, R).
remove(W, Id, NW) :- select(O, W.items, R), O.id == Id, !, NW = W.put(items, R).
remove(W, Id, NW) :- select(O, W.plyrs, R), O.id == Id, !, NW = W.put(plyrs, R).

room_entities(W, RId, Ents) :-
    findall(E, (
        (member(E, W.plyrs) ; member(E, W.mobs) ; member(E, W.items)),
        E.room == RId
    ), Ents).
