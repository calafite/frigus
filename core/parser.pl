:- module(parser, [parse_act/2, ensure_atom/2]).

ensure_atom(Var, unknown) :- var(Var), !.
ensure_atom(Atom, CleanAtom) :-
    atom(Atom), !, normalize_space(atom(CleanAtom), Atom).
ensure_atom(String, CleanAtom) :-
    string(String), !, normalize_space(atom(CleanAtom), String).
ensure_atom(Number, Atom) :-
    number(Number), !, atom_number(Atom, Number).
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

parse_act(D, validate_key(Key)) :-
    get_dict(type, D, "validate_key"),
    ( get_dict(key, D, RawK) -> ensure_atom(RawK, Key) ; Key = "" ).

parse_act(D, login(Pass)) :-
    get_dict(type, D, "login"),
    ( get_dict(pass, D, RawP) -> ensure_atom(RawP, Pass) ; Pass = "" ).

parse_act(D, register(Pass, Key, Race, Stats)) :-
    get_dict(type, D, "register"),
    ( get_dict(pass, D, RawP) -> ensure_atom(RawP, Pass) ; Pass = "" ),
    ( get_dict(key, D, RawK) -> ensure_atom(RawK, Key) ; Key = "" ),
    ( get_dict(race, D, RawR) -> ensure_atom(RawR, Race) ; Race = human ),
    ( get_dict(stats, D, SDict), is_dict(SDict) -> Stats = SDict ; Stats = dict{} ).

parse_act(D, admin_cmd(SubCmd, Arg)) :-
    get_dict(type, D, "admin"),
    ( get_dict(sub, D, RawS) -> ensure_atom(RawS, SubCmd) ; SubCmd = none ),
    ( get_dict(target, D, RawA) -> ensure_atom(RawA, Arg) ; Arg = none ).

parse_act(D, move(Dir)) :- ( get_dict(type, D, "move") ; get_dict(type, D, "go") ), extract_dir(D, Dir).
parse_act(D, kill(Tgt)) :- ( get_dict(type, D, "kill") ; get_dict(type, D, "attack") ; get_dict(type, D, "k") ), extract_target(D, Tgt).
parse_act(D, cast(S, T)):-
    ( get_dict(type, D, "cast") ; get_dict(type, D, "c") ),
    ( get_dict(spell, D, RawS), RawS \== "" -> ensure_atom(RawS, S) ; get_dict(args, D, [RawS|_]), RawS \== "" -> ensure_atom(RawS, S) ; S = fireball ),
    ( get_dict(target, D, RawT), RawT \== "" -> ensure_atom(RawT, T) ; get_dict(args, D, [_, RawT|_]), RawT \== "" -> ensure_atom(RawT, T) ; T = none ).

parse_act(D, loot(IId))     :- ( get_dict(type, D, "loot") ; get_dict(type, D, "get") ; get_dict(type, D, "take") ; get_dict(type, D, "g") ), extract_target(D, IId).
parse_act(D, equip(I))      :- get_dict(type, D, "equip"), extract_target(D, I).
parse_act(D, unequip(S))    :- get_dict(type, D, "unequip"), extract_target(D, S).
parse_act(D, use(I))        :- get_dict(type, D, "use"), extract_target(D, I).
parse_act(D, allocate(S))   :- ( get_dict(type, D, "allocate") ; get_dict(type, D, "train") ; get_dict(type, D, "add_stat") ), extract_target(D, S).

parse_act(D, look)          :- get_dict(type, D, "look").
parse_act(D, status)        :- get_dict(type, D, "status").
parse_act(D, inventory)     :- get_dict(type, D, "inventory").
parse_act(D, bounties)      :- ( get_dict(type, D, "bounties") ; get_dict(type, D, "bounty") ).
parse_act(D, pay_bounty)    :- ( get_dict(type, D, "pay_bounty") ; get_dict(type, D, "pay") ; get_dict(type, D, "pardon") ).
parse_act(D, time)          :- ( get_dict(type, D, "time") ; get_dict(type, D, "weather") ; get_dict(type, D, "env") ).
parse_act(D, help)          :- ( get_dict(type, D, "help") ; get_dict(type, D, "local_help") ).
parse_act(D, ai_tick)       :- get_dict(type, D, "ai_tick").
parse_act(D, tick)          :- get_dict(type, D, "tick").
parse_act(D, respawn)       :- get_dict(type, D, "respawn").
