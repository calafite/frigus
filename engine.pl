:- module(engine, [api_step/2]).

:- use_module(world).
:- use_module(entity).
:- use_module(move).
:- use_module(combat).
:- use_module(item).
:- use_module(npc).
:- use_module(ai).

step(W, Id, move(Dir), NW, Evts) :- step_move(W, Id, Dir, NW, Evts).
step(W, Id, kill(TId), NW, Evts) :- step_kill(W, Id, TId, NW, Evts).
step(W, Id, cast(Sp, TId), NW, Evts) :- step_cast(W, Id, Sp, TId, NW, Evts).
step(W, Id, loot(IId), NW, Evts) :- step_loot(W, Id, IId, NW, Evts).
step(W, Id, equip(Tag), NW, Evts) :- step_equip(W, Id, Tag, NW, Evts).
step(W, Id, use(Tag), NW, Evts) :- step_use(W, Id, Tag, NW, Evts).
step(W, Id, talk(TId), NW, Evts) :- step_talk(W, Id, TId, NW, Evts).
step(W, Id, buy(TId, T, Q), NW, Evts) :- step_buy(W, Id, TId, T, Q, NW, Evts).
step(W, Id, sell(TId, T, Q), NW, Evts) :- step_sell(W, Id, TId, T, Q, NW, Evts).
step(W, Id, steal(TId, T, Q), NW, Evts) :- step_steal(W, Id, TId, T, Q, NW, Evts).
step(W, Id, ai_tick, NW, Evts) :- step_ai(W, Id, NW, Evts).

step(W, Id, look, W, [look(RId, Desc, Props, Exits, OIds, MIds, IData)]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, Node),
    Desc = Node.desc,
    Props = Node.props,
    dict_keys(Node.exits, Exits),
    world:room_entities(W, RId, Ents),
    findall(E.id, (member(E, Ents), is_dict(E, plyr), E.id \= Id), OIds),
    findall(E.id, (member(E, Ents), is_dict(E, mob), alive(E)), MIds),
    findall(item{id: E.id, tag: E.tag, qty: E.qty},
           (member(E, Ents), is_dict(E, item)), IData).

to_act(D, move(Dir)) :- D.type == "move", atom_string(Dir, D.dir).
to_act(D, look)      :- D.type == "look".
to_act(D, kill(T))   :- D.type == "kill", atom_string(T, D.target).
to_act(D, cast(S, T)):- D.type == "cast", atom_string(S, D.spell), atom_string(T, D.target).
to_act(D, loot(T))   :- D.type == "loot", atom_string(T, D.target).
to_act(D, equip(I))  :- D.type == "equip", atom_string(I, D.item).
to_act(D, use(I))    :- D.type == "use", atom_string(I, D.item).
to_act(D, talk(T))   :- D.type == "talk", atom_string(T, D.target).
to_act(D, buy(T, I, Q)) :- D.type == "buy", atom_string(T, D.target), atom_string(I, D.item), Q = D.qty.
to_act(D, sell(T, I, Q)):- D.type == "sell", atom_string(T, D.target), atom_string(I, D.item), Q = D.qty.
to_act(D, steal(T, I, Q)):- D.type == "steal", atom_string(T, D.target), atom_string(I, D.item), Q = D.qty.
to_act(D, ai_tick)   :- D.type == "ai_tick".

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NW, Evts),
    Res = json{state: NW, events: Evts}.
