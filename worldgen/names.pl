:- module(names, [
    gen_npc_name/3,
    gen_creature_name/3,
    reload_databases/0
]).

:- use_module('rng').
:- use_module(library(lists)).

:- dynamic first_name/1.
:- dynamic last_name/1.
:- dynamic creature_prefix/1.
:- dynamic creature_suffix/1.

:- initialization(reload_databases).

reload_databases :-
    retractall(first_name(_)),
    retractall(last_name(_)),
    retractall(creature_prefix(_)),
    retractall(creature_suffix(_)),
    load_file_to_pred('data/first_names.txt', first_name),
    load_file_to_pred('data/last_names.txt', last_name),
    load_file_to_pred('data/creature_prefixes.txt', creature_prefix),
    load_file_to_pred('data/creature_suffixes.txt', creature_suffix).

gen_npc_name(Seed, Name, NSeed) :-
    findall(F, first_name(F), Firsts),
    findall(L, last_name(L), Lasts),
    rng:lcg_member(Seed, Firsts, First, S1),
    rng:lcg_member(S1, Lasts, Last, NSeed),
    atomic_list_concat([First, ' ', Last], Name), !.
gen_npc_name(Seed, "Stranger", NSeed) :-
    rng:lcg(Seed, NSeed).

gen_creature_name(Seed, Name, NSeed) :-
    findall(P, creature_prefix(P), Prefixes),
    findall(S, creature_suffix(S), Suffixes),
    rng:lcg_member(Seed, Prefixes, Prefix, S1),
    rng:lcg_member(S1, Suffixes, Suffix, NSeed),
    atomic_list_concat([Prefix, ' ', Suffix], Name), !.
gen_creature_name(Seed, "Feral Beast", NSeed) :-
    rng:lcg(Seed, NSeed).

load_file_to_pred(File, Pred) :-
    exists_file(File), !,
    setup_call_cleanup(
        open(File, read, Stream),
        read_lines(Stream, Lines),
        close(Stream)
    ),
    assert_lines(Lines, Pred).
load_file_to_pred(File, Pred) :-
    format(user_error, 'Warning: Name file ~w not found. Seeding default backups.~n', [File]),
    seed_backups(Pred).

read_lines(Stream, []) :-
    at_end_of_stream(Stream), !.
read_lines(Stream, [Line|Lines]) :-
    read_line_to_string(Stream, RawLine),
    string_trim(RawLine, Line),
    read_lines(Stream, Lines).

assert_lines([], _).
assert_lines([Line|Ts], Pred) :-
    ( Line == "" -> true
    ; sub_string(Line, 0, 1, _, "#") -> true
    ;
        atom_string(Atom, Line),
        Goal =.. [Pred, Atom],
        assertz(Goal)
    ),
    assert_lines(Ts, Pred).

string_trim(StrIn, StrOut) :-
    normalize_space(string(StrOut), StrIn).

seed_backups(first_name) :-
    forall(member(N, ['Grom', 'Thok', 'Gar', 'Morg', 'Bob', 'Sam', 'Ted', 'Silvia', 'Luke']), assertz(first_name(N))).
seed_backups(last_name) :-
    forall(member(N, ['the Brave', 'Stonefist', 'Shadowweaver', 'Ironbender', 'Farmer']), assertz(last_name(N))).
seed_backups(creature_prefix) :-
    forall(member(N, ['Savage', 'Vile', 'Bloody', 'Undying', 'Rabid', 'Fiery', 'Frost']), assertz(creature_prefix(N))).
seed_backups(creature_suffix) :-
    forall(member(N, ['Stalker', 'Slayer', 'Fiend', 'Beast', 'Crawler', 'Spitfire']), assertz(creature_suffix(N))).
