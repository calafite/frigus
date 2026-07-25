:- module(chat, [do_say/3, do_party_say/3, do_channel_chat/4]).

:- use_module('../core/world').
:- use_module('combat').

do_channel_chat(room, Id, Text, Evts) :-
    ( world:get_entity(Id, Actor) ->
        combat:get_display_name(Actor, Name)
    ; Name = Id ),
    Evts = [say(Name, Text)].

do_channel_chat(party(PartyId), Id, Text, Evts) :-
    ( world:get_entity(Id, Actor) ->
        combat:get_display_name(Actor, Name)
    ; Name = Id ),
    world:push_party_event(PartyId, party_chat(Name, Text)),
    Evts = []. % Returning empty; Server multiplexer pushes it directly.

do_say(Id, Text, Evts) :-
    ( Text == "" -> Evts = [error(empty_message)]
    ; do_channel_chat(room, Id, Text, Evts)
    ).

do_party_say(Id, Text, Evts) :-
    ( Text == "" -> Evts = [error(empty_message)]
    ; world:get_entity(Id, Actor), get_dict(party, Actor, PartyId) ->
        do_channel_chat(party(PartyId), Id, Text, Evts)
    ; Evts = [error(not_in_party)]
    ).
