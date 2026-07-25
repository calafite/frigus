:- module(quest_report, [
              build_quest_list_html/2,
              build_quest_read_html/7,
              build_all_progress_html/2,
              build_single_progress_html/6
                        ]).

:- use_module('../../config/quest').
:- use_module('../combat/core').
:- use_module('mechanics').
:- use_module(library(lists)).
:- use_module(library(apply)).

% ---------------------------------------------------------
% HTML Report Builders
% ---------------------------------------------------------

build_quest_list_html(Quests, Html) :-
    foldl(format_quest_list_item, Quests, "", ListHtml),
    format(string(Html), "<div style='border:1px solid var(--gold); padding:12px; border-radius:6px; background:var(--bg-surface); margin:6px 0;'>\n            <strong style='color:var(--gold);'>--- QUEST BOARD ---</strong><br>\n            <div style='margin-top:8px;'>~w</div>\n            <span style='color:var(--text-muted); font-size:0.85em;'>Use <i>quest read &lt;id&gt;</i> for details.</span></div>", [ListHtml]).

format_quest_list_item(QId-Name-Lvl, Acc, Res) :-
    combat_core:to_atom(QId, QIdAtom),
    format(string(Item), "• <strong>~w</strong> (Lvl ~w) - ID: <i>~w</i><br>", [Name, Lvl, QIdAtom]),
    string_concat(Acc, Item, Res).

build_quest_read_html(QId, Name, Desc, RecLvl, Objs, Rewards, Html) :-
    combat_core:to_atom(QId, QIdAtom),
    format_objs(Objs, ObjsHtml),
    format_rewards(Rewards, RewHtml),
    format(string(Html), "<div style='border:1px solid var(--accent); padding:12px; border-radius:6px; background:var(--bg-surface); margin:6px 0;'>\n            <strong style='color:var(--accent); font-size:1.1em;'>~w</strong> (Rec. Lvl: ~w)<br>\n            <p style='color:var(--text-main); margin:8px 0; font-style:italic;'>\"~w\"</p>\n            <strong>Objectives:</strong><br>~w<br>\n            <strong>Rewards:</strong><br>~w<br>\n            <span style='color:var(--text-muted); font-size:0.85em;'>Use <i>quest accept ~w</i> to take this quest.</span></div>", [Name, RecLvl, Desc, ObjsHtml, RewHtml, QIdAtom]).

format_objs([], "").
format_objs([kill(Tag, Qty)|Rest], Html) :-
    format_objs(Rest, RHtml),
    combat_core:to_atom(Tag, TagAtom),
    format(string(Item), " - Kill ~w x~w<br>", [TagAtom, Qty]),
    string_concat(Item, RHtml, Html).
format_objs([collect(Tag, Qty)|Rest], Html) :-
    format_objs(Rest, RHtml),
    combat_core:to_atom(Tag, TagAtom),
    format(string(Item), " - Collect ~w x~w<br>", [TagAtom, Qty]),
    string_concat(Item, RHtml, Html).

format_rewards([], "").
format_rewards([xp(Amt)|Rest], Html) :-
    format_rewards(Rest, RHtml),
    format(string(Item), " - <span style='color:var(--success);'>~w XP</span><br>", [Amt]),
    string_concat(Item, RHtml, Html).
format_rewards([item(Tag, Qty)|Rest], Html) :-
    format_rewards(Rest, RHtml),
    combat_core:to_atom(Tag, TagAtom),
    format(string(Item), " - <span style='color:var(--gold);'>~w x~w</span><br>", [TagAtom, Qty]),
    string_concat(Item, RHtml, Html).

build_all_progress_html(Quests, Html) :-
    dict_pairs(Quests, _, Pairs),
    ( Pairs == [] -> ListHtml = "<i>No active or completed quests.</i>"
    ; foldl(format_progress_item, Pairs, "", ListHtml) ),
    format(string(Html), "<div style='border:1px solid var(--accent); padding:12px; border-radius:6px; background:var(--bg-surface); margin:6px 0;'>\n            <strong style='color:var(--accent);'>--- QUEST LOG ---</strong><br>\n            <div style='margin-top:8px;'>~w</div>\n            <span style='color:var(--text-muted); font-size:0.85em;'>Use <i>quest progress &lt;id&gt;</i> for details.</span></div>", [ListHtml]).

format_progress_item(QId-QData, Acc, Res) :-
    get_dict(status, QData, Status),
    combat_core:to_atom(QId, QIdAtom),
    ( quest_config:quest_data(QId, Name, _, _, _, _) -> true ; combat_core:to_atom(QId, Name) ),
    ( Status == completed -> Color = "var(--success)" ; Color = "var(--text-main)" ),
    format(string(Item), "• <strong style='color:~w;'>~w</strong> (<i>~w</i>) - Status: ~w<br>", [Color, Name, QIdAtom, Status]),
    string_concat(Acc, Item, Res).

build_single_progress_html(Name, Status, Prog, Objs, Actor, Html) :-
    ( Status == completed -> Color = "var(--success)" ; Color = "var(--gold)" ),
    format_prog_objs(Objs, Prog, Actor, ObjsHtml),
    format(string(Html), "<div style='border:1px solid ~w; padding:12px; border-radius:6px; background:var(--bg-surface); margin:6px 0;'>\n            <strong style='color:~w; font-size:1.1em;'>~w</strong><br>\n            Status: <strong>~w</strong><br><br>\n            <strong>Progress:</strong><br>~w</div>", [Color, Color, Name, Status, ObjsHtml]).

format_prog_objs([], _, _, "").
format_prog_objs([kill(Tag, Req)|Rest], Prog, Actor, Html) :-
    atom_concat('kill_', Tag, ProgKey),
    ( get_dict(ProgKey, Prog, Cur) -> true ; Cur = 0 ),
    format_prog_objs(Rest, Prog, Actor, RHtml),
    ( Cur >= Req -> CColor = "var(--success)" ; CColor = "var(--danger)" ),
    combat_core:to_atom(Tag, TagAtom),
    format(string(Item), " - Kill ~w: <span style='color:~w;'>~w / ~w</span><br>", [TagAtom, CColor, Cur, Req]),
    string_concat(Item, RHtml, Html).
format_prog_objs([collect(Tag, Req)|Rest], Prog, Actor, Html) :-
    quest_mechanics:get_item_qty(Actor, Tag, Cur),
    format_prog_objs(Rest, Prog, Actor, RHtml),
    ( Cur >= Req -> CColor = "var(--success)" ; CColor = "var(--danger)" ),
    combat_core:to_atom(Tag, TagAtom),
    format(string(Item), " - Collect ~w: <span style='color:~w;'>~w / ~w</span><br>", [TagAtom, CColor, Cur, Req]),
    string_concat(Item, RHtml, Html).
