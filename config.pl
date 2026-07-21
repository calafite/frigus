:- module(config, [
    dmg/2, cost/2, slot/2,
    weight/2, desc/2,
    consumable/2,
    hostile/2
]).

dmg(fists, 3).
dmg(staff, 5).
dmg(sword, 10).

cost(fireball, 5).
dmg(fireball, 12).

slot(sword, wpn).
slot(staff, wpn).
slot(shield, shield).
slot(robe, body).

weight(fists, 0).
weight(sword, 4).
weight(staff, 2).
weight(shield, 5).
weight(robe, 2).
weight(potion, 1).

desc(potion, "A bubbling red liquid.").
desc(sword, "A standard iron blade.").

consumable(potion, heal(15)).

hostile(plyr{id: A}, plyr{id: B}) :- A \= B.
hostile(plyr{id: _}, mob{id: _}).
hostile(mob{id: _}, plyr{id: _}).
