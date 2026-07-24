:- module(engine, [api_step/2, term_to_json/2, terms_to_json/2, ensure_atom/2]).

:- discontiguous step/3.
:- discontiguous parse_act/2.

:- use_module(library(md5)).
:- use_module('world').
:- use_module('../systems/move').
:- use_module('../systems/combat').
:- use_module('../systems/item').
:- use_module('../systems/status').
:- use_module('../systems/ai').
:- use_module('../systems/prog').
:- use_module('../systems/env').

step(Id, move(Dir), Evts)     :- move:do_move(Id, Dir, Evts), !.
step(Id, kill(Tgt), Evts)     :- combat:do_kill(Id, Tgt, Evts), !.
step(Id, cast(Sp, Tgt), Evts) :- combat:do_cast(Id, Sp, Tgt, Evts), !.
step(Id, loot(IId), Evts)     :- item:do_loot(Id, IId, Evts), !.
step(Id, equip(Tag), Evts)    :- item:do_equip(Id, Tag, Evts), !.
step(Id, unequip(Slot), Evts) :- item:do_unequip(Id, Slot, Evts), !.
step(Id, use(Tag), Evts)      :- item:do_use(Id, Tag, Evts), !.
step(Id, allocate(Stat), Evts):- prog:do_allocate(Id, Stat, Evts), !.

step(_, ai_tick, Evts)        :- ai:do_ai_tick(Evts), !.
step(Id, tick, Evts)          :- status:do_tick(Id, Evts), !.
step(Id, look, Evts)          :- do_look(Id, Evts), !.
step(Id, status, Evts)        :- do_status(Id, Evts), !.
step(Id, inventory, Evts)     :- do_inventory(Id, Evts), !.
step(Id, bounties, Evts)      :- do_bounties(Id, Evts), !.
step(Id, pay_bounty, Evts)    :- combat:do_pay_bounty(Id, Evts), !.
step(Id, time, Evts)          :- do_time(Id, Evts), !.
step(Id, admin_cmd(Sub, Arg), Evts) :- do_admin(Id, Sub, Arg, Evts), !.

step(Id, ensure_player(Pass, Key, Race, Stats), Evts) :-
    hash_pass(Pass, Hash),
    ( world:get_entity(Id, Player) ->
        ( get_dict(pass_hash, Player, StoredHash) ->
            ( StoredHash == Hash ->
                Evts = [player_status(Id, exists)]
            ;
                Evts = [error(invalid_password(Id))]
            )
        ;
            NPlayer = Player.put(pass_hash, Hash),
            world:put_entity(NPlayer),
            world:save_db('world_state.json'),
            Evts = [player_status(Id, exists)]
        )
    ;
        ( (is_restricted(Race), \+ admin_key(Key)) ->
            Evts = [error(restricted_race_denied(Id, Race))]
        ;
            ( admin_key(Key) -> IsAdmin = true ; IsAdmin = false ),
            ( chk_alloc(Stats, IsAdmin, CleanStats) ->
                default_player(Id, Pass, Race, IsAdmin, CleanStats, NewPlayer),
                world:put_entity(NewPlayer),
                world:save_db('world_state.json'),
                Evts = [player_status(Id, created)]
            ;
                Evts = [error(stat_allocation_invalid(Id))]
            )
        )
    ), !.

step(Id, ActTerm, [error(unhandled_action(Id, ActTerm))]).

% Server-Side Attribute Validation
chk_alloc(Stats, IsAdmin, CleanStats) :-
    ( get_dict(str, Stats, S1) -> S is max(10, S1) ; S = 10 ),
    ( get_dict(dex, Stats, D1) -> D is max(10, D1) ; D = 10 ),
    ( get_dict(con, Stats, C1) -> C is max(10, C1) ; C = 10 ),
    ( get_dict(int, Stats, I1) -> I is max(10, I1) ; I = 10 ),
    ( get_dict(wis, Stats, W1) -> W is max(10, W1) ; W = 10 ),
    ( get_dict(cha, Stats, Ch1)-> Ch is max(10, Ch1); Ch = 10 ),
    ( get_dict(luk, Stats, L1) -> L is max(10, L1) ; L = 10 ),
    Spent is (S - 10) + (D - 10) + (C - 10) + (I - 10) + (W - 10) + (Ch - 10) + (L - 10),
    ( IsAdmin == true -> MaxPts = 1000 ; MaxPts = 15 ),
    Spent =< MaxPts,
    CleanStats = dict{str: S, dex: D, con: C, int: I, wis: W, cha: Ch, luk: L}.

hash_pass(Pass, Hash) :-
    ( atom(Pass) ; string(Pass) ),
    Pass \== "", !,
    atom_string(Pass, Str),
    md5_hash(Str, Hash, []).
hash_pass(_, "nohash").

admin_key("placeholder").

is_restricted(angel).
is_restricted(demon).

% Public events are broadcast to everyone in the room. Everything else is private.
is_public_event(moved(_,_,_)).
is_public_event(hit(_,_,_,_,_)).
is_public_event(crit(_,_,_,_,_)).
is_public_event(dead(_,_)).
is_public_event(cast(_,_,_)).
is_public_event(cast_crit(_,_,_)).
is_public_event(healed(_,_,_,_)).
is_public_event(dodged(_,_)).
is_public_event(flurry(_,_)).
is_public_event(say(_,_)).
is_public_event(npc_arrived(_)).
is_public_event(guard_reinforcement(_)).
is_public_event(bounty_paid(_,_)).
is_public_event(env_msg(_)).

split_events([], [], []).
split_events([E|Es], [E|Pubs], Privs) :- is_public_event(E), !, split_events(Es, Pubs, Privs).
split_events([E|Es], Pubs, [E|Privs]) :- split_events(Es, Pubs, Privs).

api_step(Req, Res) :-
    ( catch(api_step_internal(Req, Res), Err, format_exception_res(Err, Req, Res)) ->
        true
    ;
        Res = json{status: "error", error: "Goal evaluation failed catastrophically."}
    ).

api_step_internal(Req, Res) :-
    ( get_dict(actor, Req, RawActor) -> ensure_atom(RawActor, ActorId) ; ActorId = unknown ),
    ( get_dict(action, Req, ActionDict) -> true ; ActionDict = dict{} ),
    ( parse_act(ActionDict, ActTerm) ->
        ( step(ActorId, ActTerm, DirectEvts) ->
            split_events(DirectEvts, PubEvts, PrivEvts),

            ( world:get_entity(ActorId, Actor), get_dict(room, Actor, RoomId) ->
                world:push_room_events(RoomId, PubEvts)
            ;
                true
            ),

            terms_to_json(PrivEvts, JsonPrivs),
            Res = json{status: "ok", events: JsonPrivs}
        ;
            Res = json{status: "error", error: "Action handler failed during execution", action: ActionDict}
        )
    ;
        Res = json{status: "error", error: "Malformed or unknown action payload format", action: ActionDict}
    ).

format_exception_res(Err, Req, json{status: "exception", error: ErrorMsg, req: Req}) :-
    message_to_string(Err, ErrorMsg).

ensure_atom(Var, unknown) :- var(Var), !.
ensure_atom(Atom, CleanAtom) :-
    atom(Atom), !,
    normalize_space(atom(CleanAtom), Atom).
ensure_atom(String, CleanAtom) :-
    string(String), !,
    normalize_space(atom(CleanAtom), String).
ensure_atom(Number, Atom) :-
    number(Number), !,
    atom_number(Atom, Number).
ensure_atom(_, unknown).

extract_target(D, Tgt) :-
    ( get_dict(target, D, Raw), Raw \== "" -> ensure_atom(Raw, Tgt)
    ; get_dict(args, D, [Raw|_]), Raw \== "" -> ensure_atom(Raw, Tgt)
    ; get_dict(item, D, Raw), Raw \== "" -> ensure_atom(Raw, Tgt)
    ; get_dict(stat, D, Raw), Raw \== "" -> ensure_atom(Raw, Tgt)
    ; Tgt = none ).

extract_dir(D, Dir) :-
    ( get_dict(dir, D, Raw), Raw \== "" -> ensure_atom(Raw, Dir)
    ; get_dict(args, D, [Raw|_]), Raw \== "" -> ensure_atom(Raw, Dir)
    ; Dir = north ).

parse_act(D, move(Dir)) :-
    ( get_dict(type, D, "move") ; get_dict(type, D, "go") ),
    extract_dir(D, Dir).

parse_act(D, kill(Tgt)) :-
    ( get_dict(type, D, "kill") ; get_dict(type, D, "attack") ; get_dict(type, D, "k") ),
    extract_target(D, Tgt).

parse_act(D, cast(S, T)):-
    ( get_dict(type, D, "cast") ; get_dict(type, D, "c") ),
    ( get_dict(spell, D, RawS), RawS \== "" -> ensure_atom(RawS, S)
    ; get_dict(args, D, [RawS|_]), RawS \== "" -> ensure_atom(RawS, S)
    ; S = fireball ),
    ( get_dict(target, D, RawT), RawT \== "" -> ensure_atom(RawT, T)
    ; get_dict(args, D, [_, RawT|_]), RawT \== "" -> ensure_atom(RawT, T)
    ; T = none ).

parse_act(D, loot(IId)) :-
    ( get_dict(type, D, "loot") ; get_dict(type, D, "get") ; get_dict(type, D, "take") ; get_dict(type, D, "g") ),
    extract_target(D, IId).

parse_act(D, equip(I))  :-
    get_dict(type, D, "equip"),
    extract_target(D, I).

parse_act(D, unequip(S)):-
    get_dict(type, D, "unequip"),
    extract_target(D, S).

parse_act(D, use(I))    :-
    get_dict(type, D, "use"),
    extract_target(D, I).

parse_act(D, allocate(S)) :-
    ( get_dict(type, D, "allocate") ; get_dict(type, D, "train") ; get_dict(type, D, "add_stat") ),
    extract_target(D, S).

parse_act(D, look)          :- get_dict(type, D, "look").
parse_act(D, status)        :- get_dict(type, D, "status").
parse_act(D, inventory)     :- get_dict(type, D, "inventory").
parse_act(D, bounties)      :- ( get_dict(type, D, "bounties") ; get_dict(type, D, "bounty") ).
parse_act(D, pay_bounty)    :- ( get_dict(type, D, "pay_bounty") ; get_dict(type, D, "pay") ; get_dict(type, D, "pardon") ).
parse_act(D, time)          :- ( get_dict(type, D, "time") ; get_dict(type, D, "weather") ; get_dict(type, D, "env") ).
parse_act(D, ai_tick)       :- get_dict(type, D, "ai_tick").
parse_act(D, tick)          :- get_dict(type, D, "tick").

parse_act(D, ensure_player(Pass, Key, Race, Stats)) :-
    get_dict(type, D, "ensure_player"),
    ( get_dict(pass, D, RawP) -> ensure_atom(RawP, Pass) ; Pass = "" ),
    ( get_dict(key, D, RawK) -> ensure_atom(RawK, Key) ; Key = "" ),
    ( get_dict(race, D, RawR) -> ensure_atom(RawR, Race) ; Race = human ),
    ( get_dict(stats, D, SDict), is_dict(SDict) -> Stats = SDict ; Stats = dict{} ).

parse_act(D, admin_cmd(SubCmd, Arg)) :-
    get_dict(type, D, "admin"),
    ( get_dict(sub, D, RawS) -> ensure_atom(RawS, SubCmd) ; SubCmd = none ),
    ( get_dict(target, D, RawA) -> ensure_atom(RawA, Arg) ; Arg = none ).

is_plyr(E) :- is_dict(E, plyr), !.
is_plyr(E) :- is_dict(E), get_dict(tag, E, player).

is_item(E) :- is_dict(E, item), !.
is_item(E) :- is_dict(E), get_dict(qty, E, _).

is_mob(E) :- is_dict(E, mob), !.
is_mob(E) :- is_dict(E), \+ is_plyr(E), \+ is_item(E), get_dict(hp, E, _).

do_look(Id, Evts) :-
    ( world:get_entity(Id, A) ->
        get_dict(room, A, RoomId),
        ( world:get_room(RoomId, Node) ->
            get_dict(id, Node, RId),
            ( get_dict(desc, Node, Desc) -> true ; Desc = "A room." ),
            ( get_dict(props, Node, Props) -> true ; Props = [] ),
            ( get_dict(exits, Node, ExitsDict), dict_keys(ExitsDict, Exits) -> true ; Exits = [] ),
            world:room_entities(RId, Ents),
            get_dict(hp, A, SelfHp), get_dict(max_hp, A, SelfMaxHp),
            get_dict(mp, A, SelfMp), get_dict(max_mp, A, SelfMaxMp),
            SelfStats = dict{hp: SelfHp, max_hp: SelfMaxHp, mp: SelfMp, max_mp: SelfMaxMp},

            ( get_dict(type, Node, outdoor) ->
                world:env_state(EnvState),
                env:env_desc(EnvState, EnvDesc)
            ;
                EnvDesc = ""
            ),

            findall(dict{id: OId, hp: OHp, max_hp: OMaxHp, bounty: OBty},
                    (member(O, Ents), is_plyr(O), get_dict(id, O, OId), OId \== Id,
                     get_dict(hp, O, OHp), get_dict(max_hp, O, OMaxHp), (get_dict(bounty, O, OBty) -> true ; OBty = 0)), OData),
            findall(dict{id: MId, name: MName, tag: MTag, hp: MHp, max_hp: MMaxHp},
                    (member(M, Ents), is_mob(M), get_dict(hp, M, MHp), MHp > 0,
                     get_dict(id, M, MId), (get_dict(name, M, MName) -> true ; MName = MTag),
                     get_dict(tag, M, MTag), (get_dict(max_hp, M, MMaxHp) -> true ; MMaxHp = MHp)), MData),
            findall(dict{id: IId, tag: ITag, qty: IQty},
                    (member(I, Ents), is_item(I), get_dict(id, I, IId),
                     get_dict(tag, I, ITag), get_dict(qty, I, IQty)), IData),
            Evts = [look(RId, Desc, Props, Exits, OData, MData, IData, SelfStats, EnvDesc)]
        ;
            Evts = [error(room_not_found(RoomId))]
        )
    ;
        Evts = [error(actor_not_found(Id))]
    ).

do_status(Id, [status_info(Id, Lvl, Xp, ReqXp, StatPoints, Stats, Health, Bty)]) :-
    world:get_entity(Id, A), !,
    get_dict(hp, A, Hp), get_dict(max_hp, A, MaxHp),
    get_dict(mp, A, Mp), get_dict(max_mp, A, MaxMp),
    get_dict(lvl, A, Lvl), get_dict(xp, A, Xp),
    ReqXp is Lvl * Lvl * 100,
    ( get_dict(stat_points, A, StatPoints) -> true ; StatPoints = 0 ),
    ( get_dict(bounty, A, Bty) -> true ; Bty = 0 ),
    entity:get_stat(A, str, Str), entity:get_stat(A, dex, Dex),
    entity:get_stat(A, con, Con), entity:get_stat(A, int, Int),
    entity:get_stat(A, wis, Wis), entity:get_stat(A, cha, Cha),
    entity:get_stat(A, luk, Luk),
    Stats = dict{str: Str, dex: Dex, con: Con, int: Int, wis: Wis, cha: Cha, luk: Luk},
    Health = dict{hp: Hp, max_hp: MaxHp, mp: Mp, max_mp: MaxMp}.
do_status(Id, [error(actor_not_found(Id))]).

do_inventory(Id, [inventory_info(Id, Inv, Eq)]) :-
    world:get_entity(Id, A), !,
    get_dict(inv, A, Inv), get_dict(equip, A, Eq).
do_inventory(Id, [error(actor_not_found(Id))]).

do_bounties(Id, [bounty_report(Id, List)]) :-
    world:get_bounty_leaderboard(10, List).

do_time(Id, [time_report(Id, Desc)]) :-
    world:env_state(Env),
    env:env_desc(Env, Desc).

do_admin(Id, god, _, [admin_msg(Id, "God mode granted!")]) :-
    world:get_entity(Id, A),
    entity:check_admin(A), !,
    NA = A.put(hp, 999999).put(max_hp, 999999),
    world:put_entity(NA).
do_admin(Id, SubCmd, _, [error(unhandled_admin_cmd(Id, SubCmd))]).

default_player(Id, Pass, Race, IsAdmin, Stats, P) :-
    hash_pass(Pass, Hash),
    get_dict(str, Stats, S), get_dict(dex, Stats, D), get_dict(con, Stats, C),
    get_dict(int, Stats, I), get_dict(wis, Stats, W), get_dict(cha, Stats, Ch), get_dict(luk, Stats, L),
    MaxHp is 50 + (C - 10) * 5,
    MaxMp is 20 + (I - 10) * 5,
    P = plyr{
        id: Id, tag: player, class: fighter, race: Race, lvl: 1, xp: 0,
        stat_points: 0, bounty: 0, pass_hash: Hash, admin: IsAdmin,
        hp: MaxHp, max_hp: MaxHp, mp: MaxMp, max_mp: MaxMp,
        str: S, dex: D, con: C, int: I, wis: W, cha: Ch, luk: L,
        room: square, equip: equip{wpn: fists, shield: none, body: none},
        inv: [stack{tag: gold, qty: 100}], cds: cds{}
    }.

terms_to_json([], []) :- !.
terms_to_json([H|T], [JH|JT]) :- term_to_json(H, JH), terms_to_json(T, JT).

term_to_json(Var, null) :- var(Var), !.
term_to_json(Dict, JsonDict) :-
    is_dict(Dict), !,
    dict_pairs(Dict, _, Pairs),
    map_pairs(Pairs, JsonPairs),
    dict_pairs(JsonDict, json, JsonPairs).
term_to_json(List, JsonList) :-
    is_list(List), !,
    terms_to_json(List, JsonList).
term_to_json(Atom, AtomStr) :-
    atom(Atom), \+ number(Atom), \+ member(Atom, [true, false, null]), !,
    atom_string(Atom, AtomStr).
term_to_json(Compound, json{type: TypeStr, args: JsonArgs}) :-
    compound(Compound), !,
    Compound =.. [Functor|Args],
    atom_string(Functor, TypeStr),
    terms_to_json(Args, JsonArgs).
term_to_json(Val, Val).

map_pairs([], []).
map_pairs([K-V|T], [K-JV|NT]) :- term_to_json(V, JV), map_pairs(T, NT).
