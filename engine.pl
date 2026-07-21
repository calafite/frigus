:- module(engine, [api_step/2]).

:- use_module(world).
:- use_module(entity).
:- use_module(move).
:- use_module(combat).
:- use_module(item).

step(W, Id, move(Dir), NW, Evts) :- step_move(W, Id, Dir, NW, Evts).
step(W, Id, kill(TId), NW, Evts) :- step_kill(W, Id, TId, NW, Evts).
step(W, Id, cast(Sp, TId), NW, Evts) :- step_cast(W, Id, Sp, TId, NW, Evts).
step(W, Id, loot(IId), NW, Evts) :- step_loot(W, Id, IId, NW, Evts).
step(W, Id, equip(Tag), NW, Evts) :- step_equip(W, Id, Tag, NW, Evts).

step(W, Id, look, W, [look(RId, Type, Exits, OIds, MIds, IIds)]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, Node),
    Type = Node.type,
    dict_keys(Node.exits, Exits),
    world:room_entities(W, RId, Ents),
    findall(E.id, (member(E, Ents), is_dict(E, plyr), E.id \= Id), OIds),
    findall(E.id, (member(E, Ents), is_dict(E, mob), alive(E)), MIds),
    findall(E.id, (member(E, Ents), is_dict(E, item)), IIds).

to_act(D, move(Dir)) :- D.type == "move", atom_string(Dir, D.dir).
to_act(D, look)      :- D.type == "look".
to_act(D, kill(T))   :- D.type == "kill", atom_string(T, D.target).
to_act(D, cast(S, T)):- D.type == "cast", atom_string(S, D.spell), atom_string(T, D.target).
to_act(D, loot(T))   :- D.type == "loot", atom_string(T, D.target).
to_act(D, equip(I))  :- D.type == "equip", atom_string(I, D.item).

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NW, Evts),
    Res = json{state: NW, events: Evts}.
