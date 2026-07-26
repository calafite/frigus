:- module(combat, []).

:- reexport('combat/core', [get_display_name/2]).
:- reexport('combat/factions', [do_pay_bounty/2, is_town_npc/1, is_innocent/1, is_enemy/2, is_friendly/2, is_guard/1]).
:- reexport('combat/death', [resolve_death/3]).
:- reexport('combat/melee', [do_kill/3]).
:- reexport('combat/magic', [do_cast/4]).
