:- module(engine, [api_step/2]).

:- use_module(world).
:- use_module(entity).
:- use_module(move).
:- use_module(combat).
:- use_module(magic).
:- use_module(item).
:- use_module(npc).
:- use_module(ai).
:- use_module(status).
:- use_module(visibility).
:- use_module(stealth).
:- use_module(prog).

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
step(W, Id, hide, NW, Evts) :- step_hide(W, Id, NW, Evts).
step(W, Id, train(S), NW, Evts) :- step_train(W, Id, S, NW, Evts).
step(W, Id, ai_tick, NW, Evts) :- step_ai(W, Id, NW, Evts).
step(W, Id, tick, NW, Evts) :- step_tick(W, Id, NW, Evts).

step(W, Id, look, W, [look_dark(RId)]) :-
    world:entity(W, Id, A),
    room(A, RId),
    \+ visibility:can_see(W, A, RId), !.

step(W, Id, look, W, [look(RId, Desc, Props, Exits, OIds, MIds, IData)]) :-
    world:entity(W, Id, A),
    room(A, RId),
    world:node(W, RId, Node),
    visibility:reveal_details(A, Node, Desc),
    Props = Node.props,
    visibility:revealed_exits(W, A, Node, Exits),
    world:room_entities(W, RId, Ents),
    findall(O.id, (member(O, Ents), is_dict(O, plyr), O.id \= Id, visibility:can_see_target(W, A, O)), OIds),
    findall(M.id, (member(M, Ents), is_dict(M, mob), alive(M), visibility:can_see_target(W, A, M)), MIds),
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
to_act(D, hide)      :- D.type == "hide".
to_act(D, train(S))  :- D.type == "train", atom_string(S, D.stat).
to_act(D, ai_tick)   :- D.type == "ai_tick".
to_act(D, tick)      :- D.type == "tick".

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NW, Evts),
    Res = json{state: NW, events: Evts}.
