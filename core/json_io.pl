:- module(json_io, [term_to_json/2, terms_to_json/2]).

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
