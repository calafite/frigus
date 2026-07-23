:- module(engine, [api_step/2, json_to_term/2, term_to_json/2]).

:- discontiguous step/5.

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
:- use_module(ritual).
:- use_module(mud_socket).

% Restricted race password definition
restricted_password("AETHER_PRIMORDIAL_2026").

% --- ENGINE STEP CLAUSES ---
step(W, Id, move(Dir), NW, Evts) :- step_move(W, Id, Dir, NW, Evts).
step(W, Id, kill(TId), NW, Evts) :- step_kill(W, Id, TId, NW, Evts).
step(W, Id, cast(Sp, TId), NW, Evts) :- combat:step_cast_entry(W, Id, Sp, TId, NW, Evts).
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
step(W, Id, craft(O), NW, Evts) :- craft:step_craft(W, Id, O, NW, Evts).
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
step(W, Id, disguise, NW, Evts) :- stealth:step_disguise(W, Id, NW, Evts).
step(W, Id, ritual(Type), NW, Evts) :- ritual:step_ritual(W, Id, Type, NW, Evts).
step(W, Id, socket(Item, Gem), NW, Evts) :- mud_socket:step_socket(W, Id, Item, Gem, NW, Evts).

% --- PLAYER EXISTENCE & CREATION ---
step(W, Id, player_exists, W, [player_status(Id, status(exists))]) :-
    world:entity(W, Id, _), !.
step(W, Id, player_exists, W, [player_status(Id, status(not_found))]).

step(W, Id, ensure_player, db, [player_created(Id)]) :- world:entity(W, Id, _), !.
step(_W, Id, ensure_player, db, [player_created(Id)]) :- default_player(Id, P), world:add(db, plyr, P, _).

step(_W, Id, create_player(Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, Pwd), db, [player_created(Id)]) :-
    validate_character_creation(Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, Pwd),
    build_custom_player(Id, Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, PlayerEntity),
    world:add(db, plyr, PlayerEntity, _).

% --- STATE MANAGEMENT ---
step(_W, _Id, load_state(State), db, [state_loaded]) :- !, world:load_db(State).
step(_W, _Id, dump_state, db, [state_dump(Dump)]) :- !, world:dump_db(Dump).
step(_W, _Id, clear_state, db, [state_cleared]) :- !, world:clear_db.

% --- LOOK ACTION ---
step(W, Id, look, W, [look(RId, Desc, Props, Exits, OIds, MIds, IData)]) :-
    world:entity(W, Id, A), room(A, RId), world:node(W, RId, Node),
    visibility:reveal_details(A, Node, Desc), get_dict(props, Node, Props),
    visibility:revealed_exits(W, A, Node, Exits),
    findall(OId, (world:db_entity(plyr, OId, O), OId \= Id, get_dict(room, O, RId), visibility:can_see_target(W, A, O)), OIds),
    findall(MId, (world:db_entity(mob, MId, M), alive(M), get_dict(room, M, RId), visibility:can_see_target(W, A, M)), MIds),
    findall(item{id: EId, tag: ETag, qty: EQty}, (world:db_entity(item, EId, E), get_dict(room, E, RId), get_dict(tag, E, ETag), get_dict(qty, E, EQty)), IData).

% --- SAFE ENGINE CATCH-ALL ---
step(W, Id, Act, W, [action_failed(Id, Act)]).

% --- TEMPLATES & VALIDATIONS ---
default_player(Id, P) :-
    P = plyr{
        id: Id, tag: sa, class: fighter, race: human, lvl: 1, xp: 0,
        hp: 50, max_hp: 50, mp: 20, max_mp: 20, fatigue: 0,
        str: 12, dex: 12, con: 12, int: 10, wis: 10, cha: 10, luk: 10,
        room: square, fac: citizen, equip: equip{wpn: fists, shield: none, body: none},
        inv: [stack{tag: gold, qty: 100}], affs: [], cds: cds{}, threats: dict{},
        bounty: 0, reps: reps{}, ceils: ceils{}, quests: dict{}, skills: skills{}, mems: dict{}, gender: male
    }.

% --- CHARACTER CREATION VALIDATION & BUILDER ---
validate_character_creation(Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, Pwd) :-
    validate_race(Race, Pwd),
    valid_class(Class),
    valid_gender(Gender),
    valid_weapon(Wpn),
    validate_stats(Str, Dex, Con, Int, Wis, Cha, Luk, Race).

validate_race(Race, Pwd) :-
    config:restricted_race(Race), !,
    restricted_password(MasterPwdStr),
    atom_string(MasterPwd, MasterPwdStr),
    ( Pwd == MasterPwd ; Pwd == MasterPwdStr ).
validate_race(Race, _) :-
    valid_race(Race).

valid_race(Race) :-
    member(Race, [human, elf, dwarf, orc, goblin, halfling, draconian, beastkin, merfolk, golem, undead, troll, gnome, tiefling, giant, demon, angel, demigod]).

valid_class(Class) :-
    member(Class, [fighter, wizard, rogue, cleric]).

valid_gender(Gender) :-
    member(Gender, [male, female, nonbinary]).

valid_weapon(Wpn) :-
    member(Wpn, [fists, sword, dagger, staff, shortbow, wooden_club, bronze_dagger, bronze_sword]).

validate_stats(Str, Dex, Con, Int, Wis, Cha, Luk, Race) :-
    Str >= 8, Dex >= 8, Con >= 8, Int >= 8, Wis >= 8, Cha >= 8, Luk >= 8,
    Total is Str + Dex + Con + Int + Wis + Cha + Luk,
    ( config:restricted_race(Race) -> Total =< 370 ; Total =< 85 ).

build_custom_player(Id, Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, P) :-
    ( Wpn == fists -> EquipWpn = fists ; EquipWpn = Wpn ),
    ( Wpn \== fists -> InvItems = [stack{tag: gold, qty: 100}, stack{tag: Wpn, qty: 1}] ; InvItems = [stack{tag: gold, qty: 100}] ),
    BaseHp is 30 + (Con * 2),
    BaseMp is 10 + (Int * 2),
    P = plyr{
        id: Id, tag: sa, class: Class, race: Race, lvl: 1, xp: 0,
        hp: BaseHp, max_hp: BaseHp, mp: BaseMp, max_mp: BaseMp, fatigue: 0,
        str: Str, dex: Dex, con: Con, int: Int, wis: Wis, cha: Cha, luk: Luk,
        room: square, fac: citizen, equip: equip{wpn: EquipWpn, shield: none, body: none},
        inv: InvItems, affs: [], cds: cds{}, threats: dict{},
        bounty: 0, reps: reps{}, ceils: ceils{}, quests: dict{}, skills: skills{}, mems: dict{}, gender: Gender
    }.

% --- ACTION PARSING ---
to_act(D, Act) :- get_dict(type, D, TypeStr), string_lower(TypeStr, Type), parse_act(Type, D, Act).

parse_act("player_exists", _, player_exists).
parse_act("ensure_player", _, ensure_player).
parse_act("create_player", D, create_player(Race, Class, Gender, Str, Dex, Con, Int, Wis, Cha, Luk, Wpn, Pwd)) :-
    get_dict(race, D, RS), atom_string(Race, RS),
    get_dict(class, D, CS), atom_string(Class, CS),
    get_dict(gender, D, GS), atom_string(Gender, GS),
    get_dict(str, D, Str), get_dict(dex, D, Dex), get_dict(con, D, Con),
    get_dict(int, D, Int), get_dict(wis, D, Wis), get_dict(cha, D, Cha), get_dict(luk, D, Luk),
    get_dict(starting_weapon, D, WS), atom_string(Wpn, WS),
    ( get_dict(secret_password, D, PS) -> atom_string(Pwd, PS) ; Pwd = "" ).
parse_act("move", D, move(Dir)) :- get_dict(dir, D, DS), atom_string(Dir, DS).
parse_act("look", _, look).
parse_act("kill", D, kill(T)) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("cast", D, cast(S, T)) :-
    get_dict(spell, D, SS), atom_string(S, SS),
    ( get_dict(target, D, TS) -> atom_string(T, TS) ; T = self ).
parse_act("loot", D, loot(T)) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("equip", D, equip(I)) :- get_dict(item, D, IS), atom_string(I, IS).
parse_act("unequip", D, unequip(S)) :- get_dict(slot, D, SS), atom_string(S, SS).
parse_act("use", D, use(I)) :- get_dict(item, D, IS), atom_string(I, IS).
parse_act("talk", D, talk(T)) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("buy", D, buy(T, I, Q)) :- get_dict(target, D, TS), get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(T, TS), atom_string(I, IS).
parse_act("sell", D, sell(T, I, Q)) :- get_dict(target, D, TS), get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(T, TS), atom_string(I, IS).
parse_act("steal", D, steal(T, I, Q)) :- get_dict(target, D, TS), get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(T, TS), atom_string(I, IS).
parse_act("hide", _, hide).
parse_act("train", D, train(S)) :- get_dict(stat, D, SS), atom_string(S, SS).
parse_act("pull", D, pull(Sw)) :- get_dict(switch, D, SS), atom_string(Sw, SS).
parse_act("disarm", _, disarm).
parse_act("craft", D, craft(I)) :- get_dict(item, D, IS), atom_string(I, IS).
parse_act("ai_tick", _, ai_tick).
parse_act("tick", _, tick).
parse_act("chat", D, chat(C, M)) :- get_dict(chan, D, CS), get_dict(msg, D, M), atom_string(C, CS).
parse_act("whisper", D, chat(whisper(T), M)) :- get_dict(target, D, TS), get_dict(msg, D, M), atom_string(T, TS).
parse_act("party_create", _, party(create)).
parse_act("party_invite", D, party(invite(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("party_join", D, party(join(P))) :- get_dict(party, D, PS), atom_string(P, PS).
parse_act("party_leave", _, party(leave)).
parse_act("party_kick", D, party(kick(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("guild_create", D, guild(create(N))) :- get_dict(name, D, NS), atom_string(N, NS).
parse_act("guild_invite", D, guild(invite(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("guild_join", D, guild(join(G))) :- get_dict(guild, D, GS), atom_string(G, GS).
parse_act("guild_leave", _, guild(leave)).
parse_act("guild_kick", D, guild(kick(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("guild_promote", D, guild(promote(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("guild_put", D, guild(stash_put(I, Q))) :- get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(I, IS).
parse_act("guild_take", D, guild(stash_take(I, Q))) :- get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(I, IS).
parse_act("trade_req", D, trade(req(T))) :- get_dict(target, D, TS), atom_string(T, TS).
parse_act("trade_accept", D, trade(accept(TId))) :- get_dict(trade, D, TS), atom_string(TId, TS).
parse_act("trade_add", D, trade(add(TId, I, Q))) :- get_dict(trade, D, TS), get_dict(item, D, IS), get_dict(qty, D, Q), atom_string(TId, TS), atom_string(I, IS).
parse_act("trade_gold", D, trade(gold(TId, G))) :- get_dict(trade, D, TS), get_dict(qty, D, G), atom_string(TId, TS).
parse_act("trade_ready", D, trade(ready(TId))) :- get_dict(trade, D, TS), atom_string(TId, TS).
parse_act("trade_cancel", D, trade(cancel(TId))) :- get_dict(trade, D, TS), atom_string(TId, TS).
parse_act("quest_accept", D, quest(accept(Q))) :- get_dict(quest, D, QS), atom_string(Q, QS).
parse_act("quest_turn_in", D, quest(turn_in(Q))) :- get_dict(quest, D, QS), atom_string(Q, QS).
parse_act("rest", _, rest).
parse_act("sleep", _, sleep).
parse_act("wake", _, wake).
parse_act("drink", D, drink(S)) :- (get_dict(item, D, IS) -> atom_string(S, IS) ; S = none).
parse_act("fill", _, fill).
parse_act("fish", _, fish).
parse_act("fly", D, fly(air)) :- get_dict(altitude, D, AS), AS == "air".
parse_act("fly", D, fly(ground)) :- get_dict(altitude, D, AS), AS == "ground".
parse_act("climb", _, climb).
parse_act("jump", D, jump(Dir)) :- get_dict(dir, D, DS), atom_string(Dir, DS).
parse_act("mount", D, mount(Mount)) :- get_dict(mount_tag, D, MS), atom_string(Mount, MS).
parse_act("dismount", _, dismount).
parse_act("stance", D, stance(Stance)) :- get_dict(stance, D, SS), atom_string(Stance, SS).
parse_act("search", _, search).
parse_act("travel", D, travel(Dest)) :- get_dict(destination, D, DS), atom_string(Dest, DS).
parse_act("break", D, break(ObjId)) :- get_dict(object, D, OS), atom_string(ObjId, OS).
parse_act("lock", D, lock(Dir)) :- get_dict(dir, D, DS), atom_string(Dir, DS).
parse_act("unlock", D, unlock(Dir)) :- get_dict(dir, D, DS), atom_string(Dir, DS).
parse_act("buy_property", _, buy_property).
parse_act("furniture", D, furniture(FurnId, Act)) :- get_dict(furniture, D, FS), get_dict(action, D, AS), atom_string(FurnId, FS), atom_string(Act, AS).
parse_act("pick", D, pick(Dir)) :- get_dict(dir, D, DS), atom_string(Dir, DS).
parse_act("ignite", _, ignite).
parse_act("cook", D, cook(Output)) :- get_dict(item, D, OS), atom_string(Output, OS).
parse_act("poison", D, poison(Food, Poison)) :- get_dict(item, D, FS), get_dict(poison, D, PS), atom_string(Food, FS), atom_string(Poison, PS).
parse_act("till", _, till).
parse_act("plant", D, plant(Seed)) :- get_dict(seed, D, SS), atom_string(Seed, SS).
parse_act("harvest", _, harvest).
parse_act("tame", D, tame(TgtId)) :- get_dict(target, D, TS), atom_string(TgtId, TS).
parse_act("pet_command", D, pet_command(PetId, Cmd)) :- get_dict(pet, D, PS), get_dict(command, D, CS), atom_string(PetId, PS), cmd_parse(CS, Cmd).
parse_act("pet_feed", D, pet_feed(PetId)) :- get_dict(pet, D, PS), atom_string(PetId, PS).
parse_act("pray", _, pray).
parse_act("sacrifice", D, sacrifice(Item)) :- get_dict(item, D, IS), atom_string(Item, IS).
parse_act("enchant", D, enchant(Item, Rune)) :- get_dict(item, D, IS), get_dict(rune, D, RS), atom_string(Item, IS), atom_string(Rune, RS).
parse_act("identify", D, identify(Item)) :- get_dict(item, D, IS), atom_string(Item, IS).
parse_act("repair", D, repair(Slot, Kit)) :- get_dict(slot, D, SS), get_dict(kit, D, KS), atom_string(Slot, SS), atom_string(Kit, KS).
parse_act("pay_bounty", _, pay_bounty).
parse_act("jailbreak", _, jailbreak).
parse_act("bribe", D, bribe(GuardId)) :- get_dict(target, D, TS), atom_string(GuardId, TS).
parse_act("gather", D, gather(NodeId)) :- get_dict(node, D, NS), atom_string(NodeId, NS).
parse_act("skin", D, skin(CorpseId)) :- get_dict(corpse, D, CS), atom_string(CorpseId, CS).
parse_act("build", D, build(StructTag)) :- get_dict(structure, D, SS), atom_string(StructTag, SS).
parse_act("demolish", D, demolish(Prop)) :- get_dict(prop, D, PS), atom_string(Prop, PS).
parse_act("brew", D, brew(Ingreds)) :- get_dict(ingredients, D, Is), get_ingreds(Is, Ingreds).
parse_act("ask_quest", D, ask_quest(NpcId)) :- get_dict(target, D, TS), atom_string(NpcId, TS).
parse_act("load_state", D, load_state(State)) :- get_dict(state, D, State).
parse_act("dump_state", _, dump_state).
parse_act("clear_state", _, clear_state).
parse_act("ritual", D, ritual(Type)) :- get_dict(ritual, D, RS), atom_string(Type, RS).
parse_act("socket", D, socket(Item, Gem)) :- get_dict(item, D, IS), get_dict(gem, D, GS), atom_string(Item, IS), atom_string(Gem, GS).

get_ingreds([], []).
get_ingreds([H|T], [Str|Rest]) :- atom_string(Str, H), get_ingreds(T, Rest).

cmd_parse("stay", stay).
cmd_parse("follow", follow).
cmd_parse(C, attack(Tgt)) :- sub_string(C, 0, 7, _, "attack "), sub_string(C, 7, _, 0, TgtS), atom_string(Tgt, TgtS).

% --- API HANDLERS ---
api_step(Req, Res) :-
    ( catch(api_step_internal(Req, ResDict), Err, (
            message_to_string(Err, Msg),
            ResDict = json{error: Msg}
      )) ->
        ( nonvar(ResDict) -> Res = ResDict ; Res = json{error: "Goal evaluation failed"} )
    ;
        Res = json{error: "Goal evaluation failed"}
    ).

api_step_internal(Req, json{events: JsonEvts}) :-
    get_dict(actor, Req, ActorStr), atom_string(Actor, ActorStr),
    get_dict(action, Req, ActionDict), to_act(ActionDict, Act),
    step(db, Actor, Act, _, Evts),
    terms_to_json(Evts, JsonEvts).

is_bool_or_null(true).
is_bool_or_null(false).
is_bool_or_null(@(true)).
is_bool_or_null(@(false)).
is_bool_or_null(@(null)).

% --- JSON SERIALIZATION ---
terms_to_json([], []) :- !.
terms_to_json([H|T], [JH|JT]) :- term_to_json(H, JH), terms_to_json(T, JT).

term_to_json(Var, null) :- var(Var), !.
term_to_json(Dict, JsonDict) :- is_dict(Dict), !, dict_pairs(Dict, _, Pairs), map_pairs(Pairs, JsonPairs), dict_pairs(JsonDict, json, JsonPairs).
term_to_json(List, JsonList) :- is_list(List), !, terms_to_json(List, JsonList).
term_to_json(Term, json{functor: FunctorStr, args: JsonArgs}) :- compound(Term), !, Term =.. [Functor|Args], atom_string(Functor, FunctorStr), terms_to_json(Args, JsonArgs).
term_to_json(Special, Special) :- is_bool_or_null(Special), !.
term_to_json(Atom, AtomStr) :- atom(Atom), \+ number(Atom), !, atom_string(Atom, AtomStr).
term_to_json(Val, Val).

map_pairs([], []).
map_pairs([K-V|T], [K-JV|NT]) :- term_to_json(V, JV), map_pairs(T, NT).

json_to_term(Dict, Term) :- is_dict(Dict), get_dict(functor, Dict, FunctorStr), get_dict(args, Dict, JsonArgs), !, atom_string(Functor, FunctorStr), map_json_to_terms(JsonArgs, Args), Term =.. [Functor|Args].
json_to_term(Dict, Term) :- is_dict(Dict), !, dict_pairs(Dict, Tag, Pairs), map_json_pairs(Pairs, TermPairs), dict_pairs(Term, Tag, TermPairs).
json_to_term(List, TermList) :- is_list(List), !, map_json_to_terms(List, TermList).
json_to_term(Special, Special) :- is_bool_or_null(Special), !.
json_to_term(Str, Atom) :- string(Str), !, atom_string(Atom, Str).
json_to_term(Val, Val).

map_json_to_terms([], []).
map_json_to_terms([H|T], [TH|TT]) :- json_to_term(H, TH), map_json_to_terms(T, TT).
map_json_pairs([], []).
map_json_pairs([K-V|T], [K-TV|NT]) :- json_to_term(V, TV), map_json_pairs(T, NT).
