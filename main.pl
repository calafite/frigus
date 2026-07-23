:- module(main, [start/1]).

:- use_module('core/server').
:- use_module('worldgen/builder').

start(Port) :-
    server:start_server(Port).
