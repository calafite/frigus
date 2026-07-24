:- module(dungeon, [gen_dun/5]).

:- use_module('../core/world').
:- use_module('../config/world').
:- use_module('spawn').
:- use_module('loot').
:- use_module(library(random)).
:- use_module(library(lists)).

dirs([north-south, south-north, east-west, west-east, up-down, down-up]).

rand_dir(Avoid, D, R) :- dirs(Ds), random_member(D-R, Ds), D \== Avoid, !.
rand_dir(_, D, R) :- dirs(Ds), random_member(D-R, Ds).

room_name(Theme, Name) :-
    world_config:rm_adj(Theme, Adjs), random_member(Adj, Adjs),
    world_config:rm_noun(Theme, Nouns), random_member(Noun, Nouns),
    atomic_list_concat([Adj, ' ', Noun], Name).

init_room(Id, Theme, Lvl, R) :-
    room_name(Theme, Name),
    R = dict{id: Id, type: normal, desc: Name, name: Name, exits: dict{}, props: [], theme: Theme, lvl: Lvl}.

add_exit(R, Dir, Tgt, NR) :-
    E = R.exits.put(Dir, Tgt),
    NR = R.put(exits, E).

gen_dun(Theme, Lvl, Size, EntryId, Dun) :-
    world:gen_id(room, RootId),
    init_room(EntryId, Theme, Lvl, Entry),
    add_exit(Entry, down, RootId, FEntry),
    init_room(RootId, Theme, Lvl, Root),
    add_exit(Root, up, EntryId, FRoot),
    build_path(Theme, Lvl, Size, FRoot, up, NRooms, Mobs, Items),
    Dun = dict{rooms: [FEntry  |NRooms], mobs: Mobs, items: Items}.

build_path(_, _, 0, R, _, [R], [], []) :- !.
build_path(Theme, Lvl, Len, Cur, PrevDir, Rooms, Mobs, Items) :-
    Len > 0, NLen is Len - 1,
    world:gen_id(room, NextId),
    rand_dir(PrevDir, OutDir, RevDir),
    add_exit(Cur, OutDir, NextId, FCur),
    init_room(NextId, Theme, Lvl, Next),
    add_exit(Next, RevDir, Cur.id, FNext),

    spawn:gen_grp(Theme, Lvl, NextId, NMobs),
    proc_loot:gen_chest(Lvl, NextId, NItems),

    build_path(Theme, Lvl, NLen, FNext, RevDir, RestRooms, RestMobs, RestItems),
    append([FCur], RestRooms, Rooms),
    append(NMobs, RestMobs, Mobs),
    append(NItems, RestItems, Items).
