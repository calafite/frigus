:- module(proc_dungeon, [gen_dun/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(cfg_proc).
:- use_module(proc_spawn).
:- use_module(proc_loot).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

dirs([north-south, south-north, east-west, west-east, up-down, down-up]).

rand_dir(Avoid, D, R) :- dirs(Ds), random_member(D-R, Ds), D \== Avoid, !.
rand_dir(_, D, R) :- dirs(Ds), random_member(D-R, Ds).

room_name(Theme, Name) :-
    rm_adj(Theme, Adjs), random_member(Adj, Adjs),
    rm_noun(Theme, Nouns), random_member(Noun, Nouns),
    atomic_list_concat([Adj, Noun], ' ', Name).

init_room(Id, Theme, Lvl, R) :-
    room_name(Theme, Name),
    R = dict{id: Id, type: normal, desc: Name, exits: dict{}, props: [], theme: Theme, lvl: Lvl}.

add_exit(R, Dir, Tgt, NR) :-
    E = R.exits.put(Dir, Tgt),
    NR = R.put(exits, E).

weighted_pick(Pairs, Choice) :-
    findall(W, member(_-W, Pairs), Ws),
    sum_list(Ws, Total),
    random_between(1, Total, Roll),
    pick_accum(Pairs, Roll, Choice).

pick_accum([Val-W|_], Roll, Val) :- Roll =< W, !.
pick_accum([_-W|T], Roll, Val) :- NRoll is Roll - W, pick_accum(T, NRoll, Val).

pick_theme(Theme) :-
    findall(T-W, cfg_proc:theme_weight(T, W), Pairs),
    weighted_pick(Pairs, Theme).

gen_dun(InTheme, Lvl, Size, EntryId, Dun) :-
    ( var(InTheme) -> pick_theme(Theme) ; Theme = InTheme ),
    id_gen(room, RootId),
    init_room(EntryId, Theme, Lvl, Entry),
    add_exit(Entry, down, RootId, FEntry),
    init_room(RootId, Theme, Lvl, Root),
    add_exit(Root, up, EntryId, FRoot),
    build_path(Theme, Lvl, Size, FRoot, up, NRooms, Mobs, Items),
    Dun = dict{rooms: [FEntry | NRooms], mobs: Mobs, items: Items}.

build_path(_, _, 0, R, _, [R], [], []) :- !.
build_path(Theme, Lvl, Len, Cur, PrevDir, Rooms, Mobs, Items) :-
    Len > 0,
    NLen is Len - 1,
    id_gen(room, NextId),
    rand_dir(PrevDir, OutDir, RevDir),
    add_exit(Cur, OutDir, NextId, FCur),
    init_room(NextId, Theme, Lvl, Next),
    add_exit(Next, RevDir, Cur.id, FNext),

    ( random_between(1, 100, BranchRoll), BranchRoll =< 30 ->
        id_gen(room, BId),
        rand_dir(OutDir, BDir, BRev),
        add_exit(FCur, BDir, BId, FCur2),
        init_room(BId, Theme, Lvl, BNode),
        add_exit(BNode, BRev, Cur.id, FBNode),
        proc_spawn:gen_grp(Theme, Lvl, BId, BMobs),
        proc_loot:gen_chest(Lvl, BId, BItems),
        BranchRooms = [FBNode],
        BranchMobs = BMobs,
        BranchItems = BItems
    ;
        FCur2 = FCur, BranchRooms = [], BranchMobs = [], BranchItems = []
    ),

    proc_spawn:gen_grp(Theme, Lvl, NextId, NMobs),
    proc_loot:gen_chest(Lvl, NextId, NItems),

    build_path(Theme, Lvl, NLen, FNext, RevDir, RestRooms, RestMobs, RestItems),

    append([FCur2 | BranchRooms], RestRooms, Rooms),
    append(BranchMobs, NMobs, TmpMobs),
    append(TmpMobs, RestMobs, Mobs),
    append(BranchItems, NItems, TmpItems),
    append(TmpItems, RestItems, Items).
