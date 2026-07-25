:- module(quest, [do_quest/4]).

:- reexport('quest/mechanics', [record_kill/2]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/quest').
:- use_module('quest/mechanics').
:- use_module('quest/report').

% ---------------------------------------------------------
% Core Router
% ---------------------------------------------------------

do_quest(Id, _Action, _Target, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

% LIST
do_quest(Id, list, _, Evts) :-
    quest_mechanics:check_quest_board(Id), !,
    findall(QId-Name-Lvl, quest_config:quest_data(QId, Name, _, Lvl, _, _), Quests),
    quest_report:build_quest_list_html(Quests, Html),
    Evts = [quest_report(Id, Html)].
do_quest(_, list, _, [error(no_quest_board)]).

% READ
do_quest(Id, read, Target, Evts) :-
    quest_mechanics:check_quest_board(Id), !,
    ( quest_config:quest_data(Target, Name, Desc, RecLvl, Objs, Rewards) ->
          quest_report:build_quest_read_html(Target, Name, Desc, RecLvl, Objs, Rewards, Html),
          Evts = [quest_report(Id, Html)]
    ; Evts = [error(quest_not_found)] ).
do_quest(_, read, _, [error(no_quest_board)]).

% ACCEPT
do_quest(Id, accept, Target, Evts) :-
    quest_mechanics:check_quest_board(Id), !,
    ( quest_config:quest_data(Target, Name, _, _, _, _) ->
          world:get_entity(Id, Actor),
          ( get_dict(quests, Actor, Quests) -> true ; Quests = dict{} ),
          ( get_dict(Target, Quests, QData) ->
                get_dict(status, QData, Status),
                ( Status == active -> Evts = [error(quest_already_accepted)]
                ; Status == completed -> Evts = [error(quest_already_completed)]
                ; Evts = [error(unknown_quest_status)] )
          ;
            NQuests = Quests.put(Target, dict{status: active, progress: dict{}}),
            NActor = Actor.put(quests, NQuests),
            world:put_entity(NActor),
            world:save_db('world_state.json'),
            format(string(Html), "<strong style='color:var(--success);'>Quest Accepted:</strong> ~w", [Name]),
            Evts = [quest_report(Id, Html)]
          )
    ; Evts = [error(quest_not_found)] ).
do_quest(_, accept, _, [error(no_quest_board)]).

% FINISH
do_quest(Id, finish, Target, Evts) :-
    quest_mechanics:check_quest_board(Id), !,
    ( quest_config:quest_data(Target, Name, _, _, Objs, Rewards) ->
          world:get_entity(Id, Actor),
          ( get_dict(quests, Actor, Quests) -> true ; Quests = dict{} ),
          ( get_dict(Target, Quests, QData) ->
                get_dict(status, QData, Status),
                ( Status == completed -> Evts = [error(quest_already_completed)]
                ; Status == active ->
                      ( get_dict(progress, QData, Prog) -> true ; Prog = dict{} ),
                      ( quest_mechanics:verify_objectives(Actor, Prog, Objs) ->
                            quest_mechanics:consume_collect_items(Actor, Objs, ActorAfterItems),
                            NQuests = Quests.put(Target, dict{status: completed, progress: Prog}),
                            NActor = ActorAfterItems.put(quests, NQuests),
                            world:put_entity(NActor),
                            quest_mechanics:grant_rewards(Id, Rewards, RewardEvts),
                            world:save_db('world_state.json'),
                            format(string(Html), "<strong style='color:var(--gold);'>Quest Completed:</strong> ~w", [Name]),
                            append([quest_report(Id, Html)], RewardEvts, Evts)
                      ;
                        Evts = [error(quest_objectives_incomplete)]
                      )
                )
          ; Evts = [error(quest_not_accepted)] )
    ; Evts = [error(quest_not_found)] ).
do_quest(_, finish, _, [error(no_quest_board)]).

% PROGRESS
do_quest(Id, progress, Target, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(quests, Actor, Quests) -> true ; Quests = dict{} ),
    ( (Target == none ; Target == "") ->
          quest_report:build_all_progress_html(Quests, Html),
          Evts = [quest_report(Id, Html)]
    ;
      ( get_dict(Target, Quests, QData) ->
            quest_config:quest_data(Target, Name, _, _, Objs, _),
            get_dict(status, QData, Status),
            ( get_dict(progress, QData, Prog) -> true ; Prog = dict{} ),
            quest_report:build_single_progress_html(Name, Status, Prog, Objs, Actor, Html),
            Evts = [quest_report(Id, Html)]
      ;
        Evts = [error(quest_not_accepted)]
      )
    ).

do_quest(_, _, _, [error(invalid_quest_command)]).
