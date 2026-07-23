:- module(rng, [lcg/2, lcg_range/5, lcg_member/4, gen_room_desc/5]).

:- use_module(library(lists)).

lcg(S, NS) :- NS is (S * 1103515245 + 12345) mod 2147483648.

lcg_range(S, Min, Max, Val, NS) :-
    lcg(S, NS),
    Val is Min + (NS mod (Max - Min + 1)).

lcg_member(S, List, Item, NS) :-
    lcg(S, NS),
    length(List, L),
    Idx is NS mod L,
    nth0(Idx, List, Item).

adj(wild, ["overgrown", "sunlit", "shadowy", "ancient", "misty"]).
noun(wild, ["clearing", "thicket", "grove", "meadow", "ridge"]).

gen_room_desc(Theme, S, Name, Desc, NS) :-
    ( Theme == wild -> adj(wild, Adjs), noun(wild, Nouns)
    ; Adjs = ["dark", "damp", "echoing"], Nouns = ["cave", "tunnel", "chasm"] ),
    lcg_member(S, Adjs, Adj, S1),
    lcg_member(S1, Nouns, Noun, NS),
    atomic_list_concat([Adj, ' ', Noun], Name),
    atomic_list_concat(["You find yourself in a ", Name, "."], Desc).
