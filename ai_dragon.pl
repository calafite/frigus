:- module(ai_dragon, [ai_dragon_act/4]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(move).
:- use_module(combat).
:- use_module(status).
:- use_module(survival).

ai_dragon_act(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    altitude(M, Alt),
    ( Alt \== air ->
        survival:step_fly(W, Id, air, NW, Evts)
    ;
        room(M, RId),
        world:room_entities(W, RId, Ents),
        ( findall(P.id, (member(P, Ents), is_dict(P, plyr), alive(P)), Players), Players \== [] ->
            random_member(TgtId, Players),
            random_between(1, 100, Roll),
            ( Roll =< 40 ->
                combat:step_cast(W, Id, fire_breath, TgtId, W1, Evts1),
                ( world:node(W1, RId, N) ->
                    ( member(burning(_), N.props) -> select(burning(_), N.props, RestProps) ; RestProps = N.props ),
                    NN = N.put(props, [burning(3)|RestProps]),
                    world:update(W1, NN, NW),
                    append(Evts1, [room_ablaze(RId)], Evts)
                ;
                    NW = W1, Evts = Evts1
                )
            ;
                combat:step_kill(W, Id, TgtId, NW, Evts)
            )
        ;
            NW = W, Evts = []
        )
    ), !.
ai_dragon_act(W, _, W, []).
