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
:- use_module(zone).
:- use_module(cooking).
:- use_module(nature).
:- use_module(religion).
:- use_module(enchant).
:- use_module(law).
:- use_module(gather).
:- use_module(build).
:- use_module(alchemy).
:- use_module(quest_gen).

step(W, Id, move(Dir), NW, Evts) :- step_move(W, Id, Dir, NW, Evts).
step(W, Id, kill(TId), NW, Evts) :- step_kill(W, Id, TId, NW, Evts).
step(W, Id, cast(Sp, TId), NW, Evts) :- step_cast(W, Id, Sp, TId, NW, Evts).
step(W, Id, loot(IId), NW, Evts) :- step_loot(W, Id, IId, NW, Evts).
step(W, Id, equip(Tag), NW, Evts) :- step_equip(W, Id, Tag, NW, Evts).
step(W, Id, unequip(Slot), NW, Evts) :- step_unequip(W, Id, Slot, NW, Evts).
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
step(W, Id, break(ObjId), NW, Evts) :- zone:step_break(W, Id, ObjId, NW, Evts).
step(W, Id, lock(Dir), NW, Evts) :- zone:step_lock(W, Id, Dir, NW, Evts).
step(W, Id, unlock(Dir), NW, Evts) :- zone:step_unlock(W, Id, Dir, NW, Evts).
step(W, Id, buy_property, NW, Evts) :- zone:step_buy(W, Id, NW, Evts).
step(W, Id, furniture(FurnId, Act), NW, Evts) :- zone:step_furn(W, Id, FurnId, Act, NW, Evts).
step(W, Id, pick(Dir), NW, Evts) :- zone:step_pick(W, Id, Dir, NW, Evts).
step(W, Id, ignite, NW, Evts) :- interact:step_ignite(W, Id, NW, Evts).
step(W, Id, cook(Output), NW, Evts) :- cooking:step_cook(W, Id, Output, NW, Evts).
step(W, Id, poison(Food, Poison), NW, Evts) :- cooking:step_poison(W, Id, Food, Poison, NW, Evts).
step(W, Id, till, NW, Evts) :- nature:step_till(W, Id, NW, Evts).
step(W, Id, plant(Seed), NW, Evts) :- nature:step_plant(W, Id, Seed, NW, Evts).
step(W, Id, harvest, NW, Evts) :- nature:step_harvest(W, Id, NW, Evts).
step(W, Id, tame(TgtId), NW, Evts) :- nature:step_tame(W, Id, TgtId, NW, Evts).
step(W, Id, pet_command(PetId, Cmd), NW, Evts) :- nature:step_command(W, Id, PetId, Cmd, NW, Evts).
step(W, Id, pet_feed(PetId), NW, Evts) :- nature:step_feed(W, Id, PetId, NW, Evts).
step(W, Id, pray, NW, Evts) :- religion:step_pray(W, Id, NW, Evts).
step(W, Id, sacrifice(Item), NW, Evts) :- religion:step_sacrifice(W, Id, Item, NW, Evts).
step(W, Id, enchant(Item, Rune), NW, Evts) :- enchant:step_enchant(W, Id, Item, Rune, NW, Evts).
step(W, Id, identify(Item), NW, Evts) :- enchant:step_identify(W, Id, Item, NW, Evts).
step(W, Id, repair(Slot, Kit), NW, Evts) :- enchant:step_repair(W, Id, Slot, Kit, NW, Evts).
step(W, Id, pay_bounty, NW, Evts) :- law:step_pay_bounty(W, Id, NW, Evts).
step(W, Id, jailbreak, NW, Evts) :- law:step_jailbreak(W, Id, NW, Evts).
step(W, Id, bribe(GuardId), NW, Evts) :- law:step_bribe_guard(W, Id, GuardId, NW, Evts).
step(W, Id, gather(NodeId), NW, Evts) :- gather:step_gather(W, Id, NodeId, NW, Evts).
step(W, Id, skin(CorpseId), NW, Evts) :- gather:step_skin(W, Id, CorpseId, NW, Evts).
step(W, Id, build(StructTag), NW, Evts) :- build:step_build(W, Id, StructTag, NW, Evts).
step(W, Id, demolish(Prop), NW, Evts) :- build:step_demolish(W, Id, Prop, NW, Evts).
step(W, Id, brew(Ingreds), NW, Evts) :- alchemy:step_brew(W, Id, Ingreds, NW, Evts).
step(W, Id, ask_quest(NpcId), NW, Evts) :- quest_gen:step_ask_quest(W, Id, NpcId, NW, Evts).

step(W, Id, load_state(State), db, [state_loaded]) :- !,
    world:load_db(State).
step(W, Id, dump_state, db, [state_dump(Dump)]) :- !,
    world:dump_db(Dump).
step(W, Id, clear_state, db, [state_cleared]) :- !,
    world:clear_db.

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
to_act(D, unequip(S)) :- D.type == "unequip", atom_string(S, D.slot).
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
to_act(D, break(ObjId)) :- D.type == "break", atom_string(ObjId, D.object).
to_act(D, lock(Dir)) :- D.type == "lock", atom_string(Dir, D.dir).
to_act(D, unlock(Dir)) :- D.type == "unlock", atom_string(Dir, D.dir).
to_act(D, buy_property) :- D.type == "buy_property".
to_act(D, furniture(FurnId, Act)) :- D.type == "furniture", atom_string(FurnId, D.furniture), atom_string(Act, D.action).
to_act(D, pick(Dir)) :- D.type == "pick", atom_string(Dir, D.dir).
to_act(D, ignite) :- D.type == "ignite".
to_act(D, cook(Output)) :- D.type == "cook", atom_string(Output, D.item).
to_act(D, poison(Food, Poison)) :- D.type == "poison", atom_string(Food, D.item), atom_string(Poison, D.poison).
to_act(D, till) :- D.type == "till".
to_act(D, plant(Seed)) :- D.type == "plant", atom_string(Seed, D.seed).
to_act(D, harvest) :- D.type == "harvest".
to_act(D, tame(TgtId)) :- D.type == "tame", atom_string(TgtId, D.target).
to_act(D, pet_command(PetId, Cmd)) :- D.type == "pet_command", atom_string(PetId, D.pet), cmd_parse(D.command, Cmd).
to_act(D, pet_feed(PetId)) :- D.type == "pet_feed", atom_string(PetId, D.pet).
to_act(D, pray) :- D.type == "pray".
to_act(D, sacrifice(Item)) :- D.type == "sacrifice", atom_string(Item, D.item).
to_act(D, enchant(Item, Rune)) :- D.type == "enchant", atom_string(Item, D.item), atom_string(Rune, D.rune).
to_act(D, identify(Item)) :- D.type == "identify", atom_string(Item, D.item).
to_act(D, repair(Slot, Kit)) :- D.type == "repair", atom_string(Slot, D.slot), atom_string(Kit, D.kit).
to_act(D, pay_bounty) :- D.type == "pay_bounty".
to_act(D, jailbreak) :- D.type == "jailbreak".
to_act(D, bribe(GuardId)) :- D.type == "bribe", atom_string(GuardId, D.target).
to_act(D, gather(NodeId)) :- D.type == "gather", atom_string(NodeId, D.node).
to_act(D, skin(CorpseId)) :- D.type == "skin", atom_string(CorpseId, D.corpse).
to_act(D, build(StructTag)) :- D.type == "build", atom_string(StructTag, D.structure).
to_act(D, demolish(Prop)) :- D.type == "demolish", atom_string(Prop, D.prop).
to_act(D, brew(Ingreds)) :- D.type == "brew", get_ingreds(D.ingredients, Ingreds).
to_act(D, ask_quest(NpcId)) :- D.type == "ask_quest", atom_string(NpcId, D.target).
to_act(D, load_state(State)) :- D.type == "load_state", State = D.state.
to_act(D, dump_state) :- D.type == "dump_state".
to_act(D, clear_state) :- D.type == "clear_state".

get_ingreds([], []).
get_ingreds([H|T], [Str|Rest]) :- atom_string(Str, H), get_ingreds(T, Rest).

cmd_parse("stay", stay).
cmd_parse("follow", follow).
cmd_parse(C, attack(Tgt)) :- sub_string(C, 0, 7, _, "attack "), sub_string(C, 7, _, 0, TgtS), atom_string(Tgt, TgtS).

api_step(Req, Res) :-
    to_act(Req.action, Act),
    step(db, Req.actor, Act, _, Evts),
    Res = json{events: Evts}.
