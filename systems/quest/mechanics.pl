:- module(quest_mechanics, [
    check_quest_board/1,
    verify_objectives/3,
    get_item_qty/3,
    consume_collect_items/3,
    grant_rewards/3,
    record_kill/2
]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('../../config/quest').
:- use_module('../prog').
:- use_module('../combat/core').

% ---------------------------------------------------------
% Validations & Verifications
% ---------------------------------------------------------

check_quest_board(Id) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, RoomId),
    world:get_room(RoomId, Room),
    get_dict(props, Room, Props),
    member(quest_board, Props).

verify_objectives(_, _, []).
verify_objectives(Actor, Prog, [kill(Tag, Req)|Rest]) :-
    atom_concat('kill_', Tag, ProgKey),
    ( get_dict(ProgKey, Prog, Cur) -> true ; Cur = 0 ),
    Cur >= Req,
    verify_objectives(Actor, Prog, Rest).
verify_objectives(Actor, Prog, [collect(Tag, Req)|Rest]) :-
    get_item_qty(Actor, Tag, Cur),
    Cur >= Req,
    verify_objectives(Actor, Prog, Rest).

get_item_qty(Actor, Tag, Qty) :-
    get_dict(inv, Actor, Inv),
    member(Stack, Inv),
    get_dict(tag, Stack, STag),
    combat_core:to_atom(STag, Tag), !,
    get_dict(qty, Stack, Qty).
get_item_qty(_, _, 0).

% ---------------------------------------------------------
% Item Consumption & Rewards
% ---------------------------------------------------------

consume_collect_items(Actor, [], Actor).
consume_collect_items(Actor, [collect(Tag, Qty)|Rest], FinalActor) :-
    entity:rem_item(Actor, Tag, Qty, TmpActor),
    consume_collect_items(TmpActor, Rest, FinalActor).
consume_collect_items(Actor, [kill(_,_)|Rest], FinalActor) :-
    consume_collect_items(Actor, Rest, FinalActor).

grant_rewards(_, [], []).
grant_rewards(Id, [xp(Amt)|Rest], Evts) :-
    prog:add_xp(Id, Amt, XpEvts),
    grant_rewards(Id, Rest, REvts),
    append(XpEvts, REvts, Evts).
grant_rewards(Id, [item(Tag, Qty)|Rest], [looted(Id, Tag, Qty)|Evts]) :-
    world:get_entity(Id, Actor),
    entity:add_item(Actor, Tag, Qty, NActor),
    world:put_entity(NActor),
    grant_rewards(Id, Rest, Evts).

% ---------------------------------------------------------
% Kill Hook Update
% ---------------------------------------------------------

record_kill(PlayerId, MobTag) :-
    world:get_entity(PlayerId, Player),
    ( get_dict(quests, Player, Quests) ->
        dict_pairs(Quests, DictTag, Pairs),
        update_kill_pairs(Pairs, MobTag, NPairs, Changed),
        ( Changed == true ->
            dict_pairs(NQuests, DictTag, NPairs),
            world:put_entity(Player.put(quests, NQuests))
        ; true )
    ; true ).

% Robust recursion that guarantees overlapping quests are ALL updated
update_kill_pairs([], _, [], false).
update_kill_pairs([QId-QData|T], MobTag, [QId-NQData|NT], ChangedOut) :-
    ( get_dict(status, QData, active),
      quest_config:quest_data(QId, _, _, _, Objectives, _),
      member(kill(MobTag, _ReqCount), Objectives)
    ->
        ( get_dict(progress, QData, Prog) -> true ; Prog = dict{} ),
        atom_concat('kill_', MobTag, ProgKey),
        ( get_dict(ProgKey, Prog, CurCount) -> true ; CurCount = 0 ),
        NCount is CurCount + 1,
        NProg = Prog.put(ProgKey, NCount),
        NQData = QData.put(progress, NProg),
        ThisChanged = true
    ;
        NQData = QData,
        ThisChanged = false
    ),
    update_kill_pairs(T, MobTag, NT, RestChanged),
    ( (ThisChanged == true ; RestChanged == true) -> ChangedOut = true ; ChangedOut = false ).
