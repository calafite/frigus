:- module(engine, [api_step/2]).

:- use_module(entity).
:- use_module(move).
:- use_module(combat).
:- use_module(item).

step(S, Id, move(Dir), NS, Evts) :- step_move(S, Id, Dir, NS, Evts).
step(S, Id, kill(TId), NS, Evts) :- step_kill(S, Id, TId, NS, Evts).
step(S, Id, cast(Sp, TId), NS, Evts) :- step_cast(S, Id, Sp, TId, NS, Evts).
step(S, Id, loot(IId), NS, Evts) :- step_loot(S, Id, IId, NS, Evts).
step(S, Id, equip(Tag), NS, Evts) :- step_equip(S, Id, Tag, NS, Evts).

step(S, Id, look, S, [look(RId, Type, Exits, OIds, MIds, IIds)]):- module(engine, [api_step/2]).

:- use_module(entity).
:- use_module(move).
:- use_module(combat).
:- use_module(item).

step(S, Id, move(Dir), NS, Evts) :- step_move(S, Id, Dir, NS, Evts).
step(S, Id, kill(TId), NS, Evts) :- step_kill(S, Id, TId, NS, Evts).
step(S, Id, cast(Sp, TId), NS, Evts) :- step_cast(S, Id, Sp, TId, NS, Evts).
step(S, Id, loot(IId), NS, Evts) :- step_loot(S, Id, IId, NS, Evts).
step(S, Id, equip(Tag), NS, Evts) :- step_equip(S, Id, Tag, NS, Evts).

step(S, Id, look, S, [look(Pos, OIds, MIds, IIds)]) :-
    has(S, Id, A),
    pos(A, Pos),
    findall(O.id, (member(O, S.plyrs), pos(O, Pos), O.id \= Id), OIds),
    findall(M.id, (member(M, S.mobs), pos(M, Pos), alive(M)), MIds),
    findall(I.id, (member(I, S.items), pos(I, Pos)), IIds).

to_act(D, move(Dir)) :- D.type == "move", atom_string(Dir, D.dir).
to_act(D, look)      :- D.type == "look".
to_act(D, kill(T))   :- D.type == "kill", atom_string(T, D.target).
to_act(D, cast(S, T)):- D.type == "cast", atom_string(S, D.spell), atom_string(T, D.target).
to_act(D, loot(T))   :- D.type == "loot", atom_string(T, D.target).
to_act(D, equip(I))  :- D.type == "equip", atom_string(I, D.item).

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NS, Evts),
    Res = json{state: NS, events: Evts}.
 :-
    has(S, Id, A),
    room(A, RId),
    node(S, RId, Node),
    Type = Node.type,
    dict_keys(Node.exits, Exits),
    findall(O.id, (member(O, S.plyrs), room(O, RId), O.id \= Id), OIds),
    findall(M.id, (member(M, S.mobs), room(M, RId), alive(M)), MIds),
    findall(I.id, (member(I, S.items), room(I, RId)), IIds).

to_act(D, move(Dir)) :- D.type == "move", atom_string(Dir, D.dir).
to_act(D, look)      :- D.type == "look".
to_act(D, kill(T))   :- D.type == "kill", atom_string(T, D.target).
to_act(D, cast(S, T)):- D.type == "cast", atom_string(S, D.spell), atom_string(T, D.target).
to_act(D, loot(T))   :- D.type == "loot", atom_string(T, D.target).
to_act(D, equip(I))  :- D.type == "equip", atom_string(I, D.item).

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NS, Evts),
    Res = json{state: NS, events: Evts}.
