:- module(chat, [do_say/3, do_channel_chat/4]).

:- use_module('../core/world').
:- use_module('combat').

do_channel_chat(room, Id, Text, Evts) :-
    ( world:get_entity(Id, Actor) ->
        combat:get_display_name(Actor, Name)
    ; Name = Id ),
    Evts = [say(Name, Text)].

do_say(Id, Text, Evts) :-
    ( Text == "" -> Evts = [error(empty_message)]
    ; do_channel_chat(room, Id, Text, Evts)
    ).
