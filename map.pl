:- module(map, [can_enter/3, on_enter/5, on_exit/5]).

:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(library(random)).
:- use_module(library(lists)).

cannot_enter(_W, A, N) :- get_dict(req_lvl, N, Lvl), lvl(A, ALvl), ALvl < Lvl.
cannot_enter(_W, A, N) :- get_dict(req_key, N, Key), inv(A, Inv), \+ member(stack{tag: Key, qty: _}, Inv).
cannot_enter(W, _A, N) :- get_dict(req_switch, N, Sw), world:flags(W, Fs), \+ get_dict(Sw, Fs, true).
cannot_enter(_W, A, N) :-
    member(deep_water, N.props),
    \+ (props(A, P), member(swimming, P)),
    \+ (inv(A, Inv), member(stack{tag: boat, qty: _}, Inv)).

can_enter(W, A, N) :- \+ cannot_enter(W, A, N).

on_exit(_W, A, _N, A, []) :- !.

on_enter(_W, A, N, NA, [teleported(A.id, TargetId)]) :-
    get_dict(teleport_target, N, TargetId), !,
    entity:room(A, TargetId, NA).

on_enter(W, A, N, NA, [teleported(A.id, TargetId)]) :-
    get_dict(type, N, teleporter), !,
    findall(R.id, member(R, W.rooms), RIds),
    random_member(TargetId, RIds),
    entity:room(A, TargetId, NA).

on_enter(_W, A, N, NA, [trap(A.id, Dmg) | AffEvts]) :-
    get_dict(trap, N, Dmg),
    hp(A, Hp),
    NHp is max(0, Hp - Dmg),
    hp(A, NHp, A1),
    ( get_dict(trap_inflicts, N, Type) ->
        status:apply_aff(A1, aff{type: Type, val: Dmg, dur: 3}, NA, AffEvts)
    ;
        NA = A1, AffEvts = []
    ), !.

on_enter(_W, A, _N, A, []).
