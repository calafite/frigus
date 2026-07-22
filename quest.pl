:- module(quest, [step_accept/5, step_turn_in/5, update_kill/4, update_talk/4]).

:- use_module(cfg_quest).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).

step_accept(W, Id, QId, NW, [quest_accepted(Id, QId)]) :-
    world:entity(W, Id, A), quests(A, Qs),
    \+ get_dict(QId, Qs, _),
    NQs = Qs.put(QId, dict{kills: dict{}, talks: [], status: active}),
    world:update(W, A.put(quests, NQs), NW).

step_turn_in(W, Id, QId, NW, [quest_done(Id, QId) | REvts]) :-
    world:entity(W, Id, A), quests(A, Qs),
    get_dict(QId, Qs, QS), QS.status == active,
    cfg_quest:quest_data(QId, Objs, Rews),
    check_objs(A, QS, Objs, NA),
    NQs = Qs.put(QId, QS.put(status, done)),
    A1 = NA.put(quests, NQs),
    grant_rews(W, A1, Rews, FinalA, REvts),
    world:update(W, FinalA, NW).

check_objs(A, _, [], A).
check_objs(A, QS, [kill(T, C)|Ts], NA) :-
    get_dict(T, QS.kills, K), K >= C, check_objs(A, QS, Ts, NA).
check_objs(A, QS, [talk(T)|Ts], NA) :-
    member(T, QS.talks), check_objs(A, QS, Ts, NA).
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
    quests(A, Qs), dict_pairs(Qs, quests, Pairs),
    do_kill(Tag, Pairs, NPairs, Evts),
    dict_pairs(NQs, quests, NPairs),
    quests(A, NQs, NA).

do_kill(_, [], [], []).
do_kill(T, [QId-QS|Ts], [QId-NQS|NTs], Evts) :-
    QS.status == active, !,
    Ks = QS.kills, ( get_dict(T, Ks, C) -> NC is C + 1 ; NC = 1 ),
    NQS = QS.put(kills, Ks.put(T, NC)),
    do_kill(T, Ts, NTs, REvts),
    ( cfg_quest:quest_data(QId, Objs, _), member(kill(T, Req), Objs), NC == Req ->
        Evts = [quest_obj(QId, kill(T, NC)) | REvts]
    ; Evts = REvts ).
do_kill(T, [P|Ts], [P|NTs], Evts) :- do_kill(T, Ts, NTs, Evts).

update_talk(A, Tag, NA, Evts) :-
    quests(A, Qs), dict_pairs(Qs, quests, Pairs),
    do_talk(Tag, Pairs, NPairs, Evts),
    dict_pairs(NQs, quests, NPairs),
    quests(A, NQs, NA).

do_talk(_, [], [], []).
do_talk(T, [QId-QS|Ts], [QId-NQS|NTs], Evts) :-
    QS.status == active, \+ member(T, QS.talks), !,
    NQS = QS.put(talks, [T|QS.talks]),
    do_talk(T, Ts, NTs, REvts),
    ( cfg_quest:quest_data(QId, Objs, _), member(talk(T), Objs) ->
        Evts = [quest_obj(QId, talk(T)) | REvts]
    ; Evts = REvts ).
do_talk(T, [P|Ts], [P|NTs], Evts) :- do_talk(T, Ts, NTs, Evts).
