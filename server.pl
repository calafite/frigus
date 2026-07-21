:- module(server, [start_server/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(engine).

:- http_handler(root(step), handle_step, [method(post)]).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format('Engine running on port ~w~n', [Port]).

handle_step(Request) :-
    http_read_json_dict(Request, Req),

    ( catch(engine:api_step(Req, Res), Err, (message_to_string(Err, Msg), Res = json{error: Msg})) ->
        true
    ;
        Res = json{error: "Action failed or invalid request format"}
    ),

    reply_json_dict(Res).
