:- module(config, [
    dmg/2,
    cost/2,
    slot/2,
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

hostile(plyr{id: A}, plyr{id: B}) :- A \= B.
hostile(plyr{id: _}, mob{id: _}).
hostile(mob{id: _}, plyr{id: _}).
