:- module(engine, [api_step/2]).

:- reexport('json_io', [term_to_json/2, terms_to_json/2]).
:- reexport('parser', [ensure_atom/2]).

:- use_module('world').
:- use_module('events').
:- use_module('parser').
:- use_module('json_io').
:- use_module('auth').

:- use_module('../systems/move').
:- use_module('../systems/combat').
:- use_module('../systems/item').
:- use_module('../systems/status').
:- use_module('../systems/ai').
:- use_module('../systems/prog').
:- use_module('../systems/env').
:- use_module('../systems/info').
:- use_module('../systems/admin').

% ROUTER
step(Id, validate_key(Key), Evts)                 :- auth:handle_validate_key(Id, Key, Evts), !.
step(Id, login(Pass), Evts)                        :- auth:handle_login(Id, Pass, Evts), !.
step(Id, register(Pass, Key, Race, S), Evts)       :- auth:handle_register(Id, Pass, Key, Race, S, Evts), !.
step(Id, respawn, Evts)                            :- status:do_respawn(Id, Evts), !.

step(Id, move(Dir), Evts)     :- move:do_move(Id, Dir, Evts), !.
step(Id, kill(Tgt), Evts)     :- combat:do_kill(Id, Tgt, Evts), !.
step(Id, cast(Sp, Tgt), Evts) :- combat:do_cast(Id, Sp, Tgt, Evts), !.
step(Id, pay_bounty, Evts)    :- combat:do_pay_bounty(Id, Evts), !.

step(Id, loot(IId), Evts)     :- item:do_loot(Id, IId, Evts), !.
step(Id, equip(Tag), Evts)    :- item:do_equip(Id, Tag, Evts), !.
step(Id, unequip(Slot), Evts) :- item:do_unequip(Id, Slot, Evts), !.
step(Id, use(Tag), Evts)      :- item:do_use(Id, Tag, Evts), !.

step(Id, allocate(Stat), Evts):- prog:do_allocate(Id, Stat, Evts), !.

step(Id, look, Evts)          :- info:do_look(Id, Evts), !.
step(Id, status, Evts)        :- info:do_status(Id, Evts), !.
step(Id, inventory, Evts)     :- info:do_inventory(Id, Evts), !.
step(Id, bounties, Evts)      :- info:do_bounties(Id, Evts), !.
step(Id, time, Evts)          :- info:do_time(Id, Evts), !.

step(Id, admin_cmd(Sub, Arg), Evts) :- admin:do_admin(Id, Sub, Arg, Evts), !.

step(_, ai_tick, Evts)        :- ai:do_ai_tick(Evts), !.
step(Id, tick, Evts)          :- status:do_tick(Id, Evts), !.

step(Id, ActTerm, [error(unhandled_action(Id, ActTerm))]).

api_step(Req, Res) :-
    ( catch(api_step_internal(Req, Res), Err, format_exception_res(Err, Req, Res)) -> true
    ; Res = json{status: "error", error: "Goal evaluation failed catastrophically."} ).

api_step_internal(Req, Res) :-
    ( get_dict(actor, Req, RawActor) -> parser:ensure_atom(RawActor, ActorId) ; ActorId = unknown ),
    ( get_dict(action, Req, ActionDict) -> true ; ActionDict = dict{} ),
    ( parser:parse_act(ActionDict, ActTerm) ->
          ( step(ActorId, ActTerm, DirectEvts) ->
                events:split_events(DirectEvts, PubEvts, PrivEvts),
                ( world:get_entity(ActorId, Actor), get_dict(room, Actor, RoomId) ->
                      world:push_room_events(RoomId, PubEvts)
                ; true ),
                json_io:terms_to_json(PrivEvts, JsonPrivs),
                Res = json{status: "ok", events: JsonPrivs}
          ; Res = json{status: "error", error: "Action handler failed during execution", action: ActionDict} )
    ; Res = json{status: "error", error: "Malformed or unknown action payload format", action: ActionDict} ).

format_exception_res(Err, Req, json{status: "exception", error: ErrorMsg, req: Req}) :-
    message_to_string(Err, ErrorMsg).
