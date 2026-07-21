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
:- use_module(interact).
:- use_module(craft).
:- use_module(social).
:- use_module(trade).
:- use_module(quest).
:- use_module(survival).

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
step(W, Id, pull(Sw), NW, Evts) :- step_pull(W, Id, Sw, NW, Evts).
step(W, Id, disarm, NW, Evts) :- step_disarm(W, Id, NW, Evts).
step(W, Id, craft(O), NW, Evts) :- step_craft(W, Id, O, NW, Evts).
step(W, Id, ai_tick, NW, Evts) :- step_ai(W, Id, NW, Evts).
step(W, Id, tick, NW, Evts) :- step_tick(W, Id, NW, Evts).
step(W, Id, chat(C, M), NW, Evts) :- social:step_chat(W, Id, C, M, NW, Evts).
step(W, Id, party(A), NW, Evts) :- social:step_party(W, Id, A, NW, Evts).
step(W, Id, guild(A), NW, Evts) :- social:step_guild(W, Id, A, NW, Evts).
step(W, Id, trade(A), NW, Evts) :- trade:step_trade(W, Id, A, NW, Evts).
step(W, Id, quest(accept(Q)), NW, Evts) :- quest:step_accept(W, Id, Q, NW, Evts).
step(W, Id, quest(turn_in(Q)), NW, Evts) :- quest:step_turn_in(W, Id, Q, NW, Evts).
step(W, Id, rest, NW, Evts) :- survival:step_rest(W, Id, NW, Evts).
step(W, Id, sleep, NW, Evts) :- survival:step_sleep(W, Id, NW, Evts).
step(W, Id, wake, NW, Evts) :- survival:step_wake(W, Id, NW, Evts).
step(W, Id, drink(S), NW, Evts) :- survival:step_drink(W, Id, S, NW, Evts).
step(W, Id, fill, NW, Evts) :- survival:step_fill(W, Id, NW, Evts).
step(W, Id, fish, NW, Evts) :- survival:step_fish(W, Id, NW, Evts).
step(W, Id, fly(Alt), NW, Evts) :- survival:step_fly(W, Id, Alt, NW, Evts).
step(W, Id, climb, NW, Evts) :- survival:step_climb(W, Id, NW, Evts).
step(W, Id, jump(Dir), NW, Evts) :- move:step_jump(W, Id, Dir, NW, Evts).
step(W, Id, mount(Mount), NW, Evts) :- survival:step_mount(W, Id, Mount, NW, Evts).
step(W, Id, dismount, NW, Evts) :- survival:step_dismount(W, Id, NW, Evts).
step(W, Id, stance(Stance), NW, Evts) :- survival:step_stance(W, Id, Stance, NW, Evts).
step(W, Id, search, NW, Evts) :- visibility:step_search(W, Id, NW, Evts).
step(W, Id, travel(Dest), NW, Evts) :- move:step_travel(W, Id, Dest, NW, Evts).

step(W, Id, look, W, [look(RId, Desc, Props, Exits, OIds, MIds, IData)]) :-
    world:entity(W, Id, A), room(A, RId), world:node(W, RId, Node),
    visibility:reveal_details(A, Node, Desc), Props = Node.props,
    visibility:revealed_exits(W, A, Node, Exits), world:room_entities(W, RId, Ents),
    findall(O.id, (member(O, Ents), is_dict(O, plyr), O.id \= Id, visibility:can_see_target(W, A, O)), OIds),
    findall(M.id, (member(M, Ents), is_dict(M, mob), alive(M), visibility:can_see_target(W, A, M)), MIds),
    findall(item{id: E.id, tag: E.tag, qty: E.qty}, (member(E, Ents), is_dict(E, item)), IData).

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
to_act(D, pull(Sw))  :- D.type == "pull", atom_string(Sw, D.switch).
to_act(D, disarm)    :- D.type == "disarm".
to_act(D, craft(I))  :- D.type == "craft", atom_string(I, D.item).
to_act(D, ai_tick)   :- D.type == "ai_tick".
to_act(D, tick)      :- D.type == "tick".

to_act(D, chat(C, M)) :- D.type == "chat", atom_string(C, D.chan), atom_string(M, D.msg).
to_act(D, chat(whisper(T), M)) :- D.type == "whisper", atom_string(T, D.target), atom_string(M, D.msg).

to_act(D, party(create)) :- D.type == "party_create".
to_act(D, party(invite(T))) :- D.type == "party_invite", atom_string(T, D.target).
to_act(D, party(join(P))) :- D.type == "party_join", atom_string(P, D.party).
to_act(D, party(leave)) :- D.type == "party_leave".
to_act(D, party(kick(T))) :- D.type == "party_kick", atom_string(T, D.target).

to_act(D, guild(create(N))) :- D.type == "guild_create", atom_string(N, D.name).
to_act(D, guild(invite(T))) :- D.type == "guild_invite", atom_string(T, D.target).
to_act(D, guild(join(G))) :- D.type == "guild_join", atom_string(G, D.guild).
to_act(D, guild(leave)) :- D.type == "guild_leave".
to_act(D, guild(kick(T))) :- D.type == "guild_kick", atom_string(T, D.target).
to_act(D, guild(promote(T))) :- D.type == "guild_promote", atom_string(T, D.target).
to_act(D, guild(stash_put(I, Q))) :- D.type == "guild_put", atom_string(I, D.item), Q = D.qty.
to_act(D, guild(stash_take(I, Q))) :- D.type == "guild_take", atom_string(I, D.item), Q = D.qty.

to_act(D, trade(req(T))) :- D.type == "trade_req", atom_string(T, D.target).
to_act(D, trade(accept(TId))) :- D.type == "trade_accept", atom_string(TId, D.trade).
to_act(D, trade(add(TId, I, Q))) :- D.type == "trade_add", atom_string(TId, D.trade), atom_string(I, D.item), Q = D.qty.
to_act(D, trade(gold(TId, G))) :- D.type == "trade_gold", atom_string(TId, D.trade), G = D.qty.
to_act(D, trade(ready(TId))) :- D.type == "trade_ready", atom_string(TId, D.trade).
to_act(D, trade(cancel(TId))) :- D.type == "trade_cancel", atom_string(TId, D.trade).

to_act(D, quest(accept(Q))) :- D.type == "quest_accept", atom_string(Q, D.quest).
to_act(D, quest(turn_in(Q))) :- D.type == "quest_turn_in", atom_string(Q, D.quest).

to_act(D, rest) :- D.type == "rest".
to_act(D, sleep) :- D.type == "sleep".
to_act(D, wake) :- D.type == "wake".
to_act(D, drink) :- D.type == "drink", \+ get_dict(item, D, _), S = room.
to_act(D, drink(S)) :- D.type == "drink", atom_string(S, D.item).
to_act(D, fill) :- D.type == "fill".
to_act(D, fish) :- D.type == "fish".
to_act(D, fly) :- D.type == "fly", atom_string(A, D.altitude), A == "air", Alt = air.
to_act(D, fly) :- D.type == "fly", atom_string(A, D.altitude), A == "ground", Alt = ground.
to_act(D, climb) :- D.type == "climb".
to_act(D, jump(Dir)) :- D.type == "jump", atom_string(Dir, D.dir).
to_act(D, mount(Mount)) :- D.type == "mount", atom_string(Mount, D.mount_tag).
to_act(D, dismount) :- D.type == "dismount".
to_act(D, stance(Stance)) :- D.type == "stance", atom_string(Stance, D.stance).
to_act(D, search) :- D.type == "search".
to_act(D, travel(Dest)) :- D.type == "travel", atom_string(Dest, D.destination).

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(Req.state, Req.actor, Act, NW, Evts),
    Res = json{state: NW, events: Evts}.
