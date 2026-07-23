:- module(ai_pet, [ai_pet_act/4]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(move).
:- use_module(combat).
:- use_module(ai_path).

ai_pet_act(W, Id, NW, Evts) :-
    world:entity(W, Id, Pet),
    ( get_dict(master, Pet, MasterId), world:entity(W, MasterId, Master) ->
        ( get_dict(command, Pet, Cmd) -> true ; Cmd = follow ),
        execute_cmd(Cmd, W, Id, Pet, Master, NW, Evts)
    ;
        NW = W, Evts = []
    ), !.
ai_pet_act(W, _, W, []).

execute_cmd(stay, W, _, _, _, W, []) :- !.

execute_cmd(follow, W, Id, Pet, Master, NW, Evts) :-
    room(Pet, PRId), room(Master, MRId),
    ( PRId \== MRId ->
        ai_path:step_towards(W, Id, MRId, NW, Evts)
    ;
        NW = W, Evts = []
    ), !.

execute_cmd(attack(TgtId), W, Id, Pet, Master, NW, Evts) :-
    room(Pet, PRId), room(Master, MRId),
    ( PRId \== MRId ->
        ai_path:step_towards(W, Id, MRId, NW, Evts)
    ;
        world:room_entities(W, PRId, Ents),
        ( member(T, Ents), T.id == TgtId, alive(T) ->
            combat:step_kill(W, Id, TgtId, NW, Evts)
        ;
            execute_cmd(follow, W, Id, Pet, Master, NW, Evts)
        )
    ), !.

execute_cmd(_, W, Id, Pet, Master, NW, Evts) :-
    execute_cmd(follow, W, Id, Pet, Master, NW, Evts).
