:- module(admin, [do_admin/4]).

:- use_module('../core/world').
:- use_module('../core/entity').

do_admin(Id, god, _, [admin_msg(Id, "God mode granted!")]) :-
    world:get_entity(Id, A), entity:check_admin(A), !,
    NA = A.put(hp, 999999).put(max_hp, 999999), world:put_entity(NA).
do_admin(Id, SubCmd, _, [error(unhandled_admin_cmd(Id, SubCmd))]).
