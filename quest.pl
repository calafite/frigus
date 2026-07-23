:- module(quest, [step_accept/5, step_turn_in/5, update_kill/4, update_talk/4]).

:- use_module(cfg_quest).
:- use_module(quest_gen).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).
:- use_module(status).
:- use_module(library(lists)).

quest_exists(QId, Objs, Rews) :-
    cfg_quest:quest_data(QId, Objs, Rews), !.
quest_exists(QId, Objs, Rews) :-
    quest_gen:db_generated_quest(_, QId, Objs, Rews), !.

step_accept(W, Id, QId, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; quests(A, Qs), is_dict(Qs), get_dict(QId, Qs, _) ->
        NW = W, Evts = [already_accepted(Id, QId)]
    ; \+ quest_exists(QId, _, _) ->
        NW = W, Evts = [unknown_quest(Id, QId)]
    ;
        ( quests(A, Qs), is_dict(Qs) -> true ; Qs = dict{} ),
        NQs = Qs.put(QId, dict{kills: dict{}, talks: [], status: active}),
        world:update(W, A.put(quests, NQs), NW),
        Evts = [quest_accepted(Id, QId)]
    ).

step_turn_in(W, Id, QId, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; quests(A, Qs), is_dict(Qs), get_dict(QId, Qs, QS), is_dict(QS), get_dict(status, QS, active) ->
        ( quest_exists(QId, Objs, Rews) ->
            ( check_objs(A, QS, Objs, NA) ->
                NQs = Qs.put(QId, QS.put(status, done)),
                A1 = NA.put(quests, NQs),
                grant_rews(W, A1, Rews, FinalA, REvts),
                world:update(W, FinalA, NW),
                Evts = [quest_done(Id, QId) | REvts]
            ;
                NW = W, Evts = [quest_incomplete(Id, QId)]
            )
        ;
            NW = W, Evts = [unknown_quest(Id, QId)]
        )
    ;
        NW = W, Evts = [quest_not_active(Id, QId)]
    ).

check_objs(A, _, [], A).
check_objs(A, QS, [kill(T, C)|Ts], NA) :-
    get_dict(kills, QS, Ks), is_dict(Ks), get_dict(T, Ks, K), K >= C,
    check_objs(A, QS, Ts, NA).
check_objs(A, QS, [talk(T)|Ts], NA) :-
    get_dict(talks, QS, Talks), is_list(Talks), member(T, Talks),
    check_objs(A, QS, Ts, NA).
check_objs(A, QS, [fetch(T, C)|Ts], NA) :-
    inv(A, Inv), inv_rem(Inv, T, C, NInv),
    check_objs(A.put(inv, NInv), QS, Ts, NA).

grant_rews(_, A, [], A, []).
grant_rews(W, A, [xp(X)|Ts], NA, [xp(A.id, FinalX)|Evts]) :-
    stat(A, wis, Wis), stat(A, int, Int), stat(A, luk, Luk),
    FinalX is X + floor(X * (Wis * 0.02)) + floor(X * (Int * 0.01)) + floor(X * (Luk * 0.01)),
    prog:add_xp(A, FinalX, TmpA, _), grant_rews(W, TmpA, Ts, NA, Evts).
grant_rews(W, A, [gold(G)|Ts], NA, Evts) :-
    stat(A, cha, Cha), stat(A, luk, Luk),
    FinalG is G + floor(G * (Cha * 0.03)) + floor(G * (Luk * 0.02)),
    inv(A, Inv), inv_add(Inv, gold, FinalG, NInv),
    grant_rews(W, A.put(inv, NInv), Ts, NA, Evts).
grant_rews(W, A, [item(T, Q)|Ts], NA, Evts) :-
    inv(A, Inv), inv_add(Inv, T, Q, NInv),
    grant_rews(W, A.put(inv, NInv), Ts, NA, Evts).

update_kill(A, Tag, NA, Evts) :-
    quests(A, Qs), is_dict(Qs), !,
    dict_pairs(Qs, TagType, Pairs),
    do_kill(Tag, Pairs, NPairs, Evts),
    dict_pairs(NQs, TagType, NPairs),
    quests(A, NQs, NA).
update_kill(A, _, A, []).

do_kill(_, [], [], []).
do_kill(T, [QId-QS|Ts], [QId-NQS|NTs], Evts) :-
    is_dict(QS), get_dict(status, QS, active), !,
    ( get_dict(kills, QS, Ks) -> true ; Ks = dict{} ),
    ( get_dict(T, Ks, C) -> NC is C + 1 ; NC = 1 ),
    NQS = QS.put(kills, Ks.put(T, NC)),
    do_kill(T, Ts, NTs, REvts),
    ( quest_exists(QId, Objs, _), member(kill(T, Req), Objs), NC == Req ->
        Evts = [quest_obj(QId, kill(T, NC)) | REvts]
    ; Evts = REvts ).
do_kill(T, [P|Ts], [P|NTs], Evts) :- do_kill(T, Ts, NTs, Evts).

update_talk(A, Tag, NA, Evts) :-
    quests(A, Qs), is_dict(Qs), !,
    dict_pairs(Qs, TagType, Pairs),
    do_talk(Tag, Pairs, NPairs, Evts),
    dict_pairs(NQs, TagType, NPairs),
    quests(A, NQs, NA).
update_talk(A, _, A, []).

do_talk(_, [], [], []).
do_talk(T, [QId-QS|Ts], [QId-NQS|NTs], Evts) :-
    is_dict(QS), get_dict(status, QS, active),
    ( get_dict(talks, QS, Talks), is_list(Talks) -> true ; Talks = [] ),
    \+ member(T, Talks), !,
    NQS = QS.put(talks, [T|Talks]),
    do_talk(T, Ts, NTs, REvts),
    ( quest_exists(QId, Objs, _), member(talk(T), Objs) ->
        Evts = [quest_obj(QId, talk(T)) | REvts]
    ; Evts = REvts ).
do_talk(T, [P|Ts], [P|NTs], Evts) :- do_talk(T, Ts, NTs, Evts).
