:- module(names, [
    gen_cell_name/4,
    gen_cell_desc/5,
    lcg/2,
    lcg_member/4,
    lcg_range/5
]).

:- use_module(library(lists)).

:- discontiguous adj/2.
:- discontiguous noun/2.

lcg(S, NS) :- NS is (S * 1103515245 + 12345) mod 2147483648.

lcg_range(S, Min, Max, Val, NS) :-
    lcg(S, NS),
    Val is Min + (NS mod (Max - Min + 1)).

lcg_member(S, List, Item, NS) :-
    lcg(S, NS),
    length(List, L),
    Idx is NS mod L,
    nth0(Idx, List, Item).

adj(civil, ["peaceful", "busy", "grand", "rustic", "cozy", "paved", "crowded"]).
noun(civil, ["outpost", "trading post", "hamlet", "borough", "square", "crossroads"]).

adj(wild, ["overgrown", "sunlit", "shadowy", "ancient", "misty", "pathless", "silent"]).
noun(wild, ["clearing", "thicket", "grove", "meadow", "ridge", "valley"]).

adj(dark, ["damp", "echoing", "forgotten", "moldering", "cold", "unholy", "sealed"]).
noun(dark, ["crypt", "catacomb", "vault", "sepulcher", "chasm", "tunnel"]).

adj(hot, ["scorched", "burning", "ash-choked", "molten", "heated", "unstable"]).
noun(hot, ["pit", "vent", "crater", "caldera", "lava field", "obsidian crag"]).

adj(cold, ["freezing", "crystalline", "slippery", "howling", "frozen", "silent"]).
noun(cold, ["glacier", "snowfield", "crevasse", "ice cavern", "tundra"]).

gen_cell_name(Theme, S, Name, NS) :-
    member(Theme, [village, city, market, castle, monastery]), !,
    lcg_member(S, ["Stone", "Oak", "River", "Deep", "Shadow", "Ash", "Wind", "Iron", "Gold", "Sun"], Pre, S1),
    lcg_member(S1, ["haven", "wood", "water", "glen", "keep", "peak", "valley", "spire", "mire", "shaft"], Mid, S2),
    lcg_member(S2, [" Town", " Outpost", " Settlement", " Market", " Sanctuary"], Suf, NS),
    atomic_list_concat([Pre, Mid, Suf], Name).

gen_cell_name(Theme, S, Name, NS) :-
    member(Theme, [crypt, tomb, prison, asylum, inferno, abyss, void]), !,
    lcg_member(S, ["Grom", "Thok", "Gar", "Gor", "Karg", "Morg", "Ugr", "Bash"], Pre, S1),
    lcg_member(S1, ["'gash", "'gorg", "'nak", "'kar", "'thor", "'ur"], Mid, S2),
    lcg_member(S2, [" Void", " Pit", " Tomb", " Abyss", " Dungeon", " Hollow"], Suf, NS),
    atomic_list_concat([Pre, Mid, Suf], Name).

gen_cell_name(_Theme, S, Name, NS) :-
    lcg_member(S, ["Black", "Wild", "Green", "White", "Gray", "Red", "Lost", "Great"], Pre, S1),
    lcg_member(S1, ["wood", "mount", "plain", "lake", "swamp", "vale", "dale", "forest"], Mid, S2),
    lcg_member(S2, [" Ridge", " Glade", " Path", " Meadow", " Wilderness"], Suf, NS),
    atomic_list_concat([Pre, Mid, Suf], Name).

gen_cell_desc(Theme, Name, S, Desc, NS) :-
    member(Theme, [village, city, market, castle, monastery]), !,
    adj(civil, Adjs), lcg_member(S, Adjs, Adj, S1),
    noun(civil, Nouns), lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat(["You stand in ", Name, ", a ", Adj, " ", Noun, " surrounded by solid walls."], "", Desc).

gen_cell_desc(Theme, Name, S, Desc, NS) :-
    member(Theme, [crypt, tomb, prison, asylum, inferno, abyss, void]), !,
    adj(dark, Adjs), lcg_member(S, Adjs, Adj, S1),
    noun(dark, Nouns), lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat(["This is the dark depths of ", Name, ", a ", Adj, " ", Noun, " where shadows shift constantly."], "", Desc).

gen_cell_desc(Theme, Name, S, Desc, NS) :-
    member(Theme, [volcano, inferno]), !,
    adj(hot, Adjs), lcg_member(S, Adjs, Adj, S1),
    noun(hot, Nouns), lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat(["The scorching heat of ", Name, " burns your skin. A ", Adj, " ", Noun, " is filled with smoke."], "", Desc).

gen_cell_desc(Theme, Name, S, Desc, NS) :-
    member(Theme, [glacier, frozen_lake]), !,
    adj(cold, Adjs), lcg_member(S, Adjs, Adj, S1),
    noun(cold, Nouns), lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat(["A biting wind howls through ", Name, ". This ", Adj, " ", Noun, " is completely frozen over."], "", Desc).

gen_cell_desc(_, Name, S, Desc, NS) :-
    adj(wild, Adjs), lcg_member(S, Adjs, Adj, S1),
    noun(wild, Nouns), lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat(["You find yourself in ", Name, ", a ", Adj, " ", Noun, " under the canopy of the overworld."], "", Desc).
