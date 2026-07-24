:- module(server, [start_server/1, flush_and_send_room_events/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/websocket)).
:- use_module(library(lists)).

:- use_module('engine').
:- use_module('world').
:- use_module('../worldgen/builder').
:- use_module('../systems/ai').
:- use_module('../systems/status').

:- dynamic active_client/2.

:- http_handler(root(ws), handle_ws, [method(get)]).
:- http_handler(root(step), handle_step, [method(post)]).

start_server(Port) :-
    init_world,
    start_ticker,
    http_server(http_dispatch, [port(Port)]),
    format('Engine running on port ~w with WebSockets at /ws~n', [Port]).

init_world :-
    ( world:load_db('world_state.json'), world:get_room(square, _) ->
        format('Loaded existing world state from world_state.json~n', [])
    ;
        format('No valid world state found. Building starter world...~n', []),
        builder:build_starter_world,
        world:save_db('world_state.json')
    ).

start_ticker :-
    thread_create(ticker_loop, _, [detached(true)]).

ticker_loop :-
    sleep(1.0),
    catch(run_world_tick, _, true),
    ticker_loop.

run_world_tick :-
    ai:do_ai_tick(_),
    forall(active_client(_, ActorId), (
        status:do_tick(ActorId, TickEvts),
        ( TickEvts \== [] ->
            ( world:get_entity(ActorId, A) ->
                get_dict(room, A, RoomId),
                world:push_room_events(RoomId, TickEvts)
            ; true )
        ; true )
    )),
    broadcast_room_events.

broadcast_room_events :-
    findall(RId, world:db_room_event(RId, _), RawRooms),
    list_to_set(RawRooms, Rooms),
    forall(member(RId, Rooms), flush_and_send_room_events(RId)).

flush_and_send_room_events(RId) :-
    world:pop_room_events(RId, Evts),
    Evts \== [], !,
    engine:terms_to_json(Evts, JsonEvts),
    Payload = json{status: "ok", type: "stream", room: RId, events: JsonEvts},
    forall((active_client(WS, ActorId), world:get_entity(ActorId, A), get_dict(room, A, RId)),
           catch(ws_send(WS, json(Payload)), _, retractall(active_client(WS, _)))).
flush_and_send_room_events(_).

handle_ws(Request) :-
    http_upgrade_to_websocket(ws_loop, [], Request).

ws_loop(WebSocket) :-
    ws_receive(WebSocket, Message, [format(json)]),
    ( get_dict(type, Message, close) ->
        retractall(active_client(WebSocket, _))
    ;
        process_ws_message(WebSocket, Message.data),
        ws_loop(WebSocket)
    ).

process_ws_message(WebSocket, Req) :-
    ( get_dict(actor, Req, RawActor) ->
        engine:ensure_atom(RawActor, ActorId),
        retractall(active_client(WebSocket, _)),
        assertz(active_client(WebSocket, ActorId))
    ;
        ActorId = unknown
    ),
    ( catch(engine:api_step(Req, Res), Err, (
            message_to_string(Err, Msg),
            Res = json{status: "exception", error: Msg}
      )) ->
        true
    ;
        Res = json{status: "error", error: "Request handler goal failed"}
    ),
    ws_send(WebSocket, json(Res)),

    ( ActorId \== unknown, world:get_entity(ActorId, Actor), get_dict(room, Actor, RoomId) ->
        flush_and_send_room_events(RoomId)
    ;
        true
    ).

handle_step(Request) :-
    http_read_json_dict(Request, Req),
    ( catch(engine:api_step(Req, Res), Err, (
            message_to_string(Err, Msg),
            Res = json{status: "exception", error: Msg}
      )) ->
        true
    ;
        Res = json{status: "error", error: "Request handler goal failed"}
    ),
    reply_json_dict(Res).
