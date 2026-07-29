:- module(server, [start_server/1, flush_and_send_room_events/1, flush_and_send_party_events/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/websocket)).
:- use_module(library(lists)).

:- use_module('engine').
:- use_module('world').
:- use_module('events').
:- use_module('../worldgen/builder').
:- use_module('../systems/ai').
:- use_module('../systems/move').
:- use_module('../systems/status').
:- use_module('../systems/env').

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
          format('Loaded existing world state from world_state.json~n', []),
          force_all_players_offline
    ;
      format('No valid world state found. Building starter world...~n', []),
      builder:build_starter_world,
      world:save_db('world_state.json')
    ).

force_all_players_offline :-
    findall(P, (world:db_entity(_, P), is_dict(P, plyr), get_dict(room, P, R), R \== offline), Players),
    forall(member(P, Players), (
        get_dict(room, P, CurRoom),
        NP = P.put(last_room, CurRoom).put(room, offline),
        world:put_entity(NP)
    )),
    ( Players \== [] -> world:save_db('world_state.json') ; true ).

start_ticker :-
    thread_create(ticker_loop, _, [detached(true)]).

ticker_loop :-
    sleep(5.0),
    catch(ignore(run_world_tick), Err, format('Ticker Error: ~w~n', [Err])),
    ticker_loop.

run_world_tick :-
    env:tick_env(EnvEvts),
    ( EnvEvts \== [] -> push_env_events(EnvEvts) ; true ),
    ai:do_ai_tick(_),
    forall(active_client(WS, ActorId), (
               status:do_tick(ActorId, TickEvts),
               move:do_tick_walk(ActorId, WalkEvts),
               append(TickEvts, WalkEvts, AllEvts),
               ( AllEvts \== [] ->
                     events:split_events(AllEvts, PubTickEvts, PrivTickEvts),
                     ( world:get_entity(ActorId, A) ->
                           get_dict(room, A, RoomId),
                           world:push_room_events(RoomId, PubTickEvts)
                     ; true ),
                     ( PrivTickEvts \== [] ->
                           engine:terms_to_json(PrivTickEvts, JsonPrivs),
                           Payload = json{status: "ok", events: JsonPrivs},
                           catch(ws_send(WS, json(Payload)), _, retractall(active_client(WS, _)))
                     ; true )
               ; true )
                                       )),
    broadcast_room_events,
    broadcast_party_events.

push_env_events(Evts) :-
    forall(world:get_room(RId, _), world:push_room_events(RId, Evts)).

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

broadcast_party_events :-
    findall(PId, world:db_party_event(PId, _), RawParties),
    list_to_set(RawParties, Parties),
    forall(member(PId, Parties), flush_and_send_party_events(PId)).

flush_and_send_party_events(PId) :-
    world:pop_party_events(PId, Evts),
    Evts \== [], !,
    engine:terms_to_json(Evts, JsonEvts),
    Payload = json{status: "ok", type: "stream", channel: "party", party_id: PId, events: JsonEvts},
    forall((active_client(WS, ActorId), world:get_entity(ActorId, A), get_dict(party, A, PId)),
           catch(ws_send(WS, json(Payload)), _, retractall(active_client(WS, _)))).
flush_and_send_party_events(_).

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

    ( ActorId \== unknown, world:get_entity(ActorId, Actor) ->
          ( get_dict(room, Actor, RoomId) -> flush_and_send_room_events(RoomId) ; true ),
          ( get_dict(party, Actor, PartyId) -> flush_and_send_party_events(PartyId) ; true )
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
