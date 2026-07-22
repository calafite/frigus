:- module(map, [can_enter/5, on_enter/5, on_exit/5]).

:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(library(random)).
:- use_module(library(lists)).

cannot_enter(_W, A, _C, N, _Dir) :- get_dict(req_lvl, N, Lvl), lvl(A, ALvl), ALvl < Lvl.
cannot_enter(_W, A, _C, N, _Dir) :- get_dict(req_key, N, Key), inv(A, Inv), \+ member(stack{tag: Key, qty: _}, Inv).
cannot_enter(W, _A, _C, N, _Dir) :- get_dict(req_switch, N, Sw), world:flags(W, Fs), \+ get_dict(Sw, Fs, true).

cannot_enter(_W, A, _C, N, _Dir) :-
    member(deep_water, N.props),
    \+ altitude(A, air),
    \+ (props(A, P), member(swimming, P)),
    \+ (inv(A, Inv), member(stack{tag: boat, qty: _}, Inv)).

cannot_enter(_W, A, C, _N, Dir) :-
    get_dict(req_climb, C, Climbs), member(Dir, Climbs),
    \+ altitude(A, air),
    \+ climb_state(A, true).

cannot_enter(_W, A, C, _N, Dir) :-
    get_dict(req_flying, C, Flights), member(Dir, Flights),
    \+ altitude(A, air).

cannot_enter(_W, A, C, _N, Dir) :-
    get_dict(chasm_exits, C, Chasms), member(Dir, Chasms),
    \+ altitude(A, air).

cannot_enter(_W, _A, C, _N, Dir) :-
    get_dict(one_way_exits, C, OneWays), member(Dir, OneWays).

cannot_enter(_W, A, _C, N, _Dir) :-
    member(narrow, N.props),
    \+ stance(A, crawl).

cannot_enter(W, _A, C, _N, Dir) :-
    get_dict(req_switch, C, Sws), get_dict(Dir, Sws, Sw),
    world:flags(W, Fs), \+ get_dict(Sw, Fs, true).

cannot_enter(_W, A, C, _N, Dir) :-
    get_dict(req_portal_key, C, Portals), get_dict(Dir, Portals, Key),
    inv(A, Inv), \+ member(stack{tag: Key, qty: _}, Inv).

cannot_enter(_W, A, _C, N, _Dir) :-
    get_dict(locked_exits, N, Locked), member(locked, Locked),
    \+ get_dict(owner, N, A.id).

cannot_enter(W, _A, _C, N, _Dir) :-
    get_dict(cap, N, Cap),
    world:room_entities(W, N.id, Ents),
    include(is_plyr, Ents, Players),
    length(Players, Count),
    Count >= Cap.

is_plyr(E) :- is_dict(E, plyr).

can_enter(W, A, C, N, Dir) :- \+ cannot_enter(W, A, C, N, Dir).

on_exit(_W, A, _N, A, []) :- !.

on_enter(W, A, N, NA, [discovered_landmark(A.id, N.id) | Evts]) :-
    member(landmark, N.props),
    get_dict(landmarks, A, Known),
    \+ member(N.id, Known), !,
    A1 = A.put(landmarks, [N.id | Known]),
    on_enter_normal(W, A1, N, NA, Evts).
on_enter(W, A, N, NA, Evts) :-
    on_enter_normal(W, A, N, NA, Evts).

on_enter_normal(W, A, N, NA, Evts) :-
    get_dict(owner, N, Owner), Owner \== none, Owner \== A.id, !,
    rep_mod(A, town, -10, A1),
    on_enter_trespass(W, A1, N, NA, Evts1),
    Evts = [trespassed(A.id, N.id) | Evts1].
on_enter_normal(W, A, N, NA, Evts) :-
    on_enter_trespass(W, A, N, NA, Evts).

on_enter_trespass(_W, A, N, NA, [teleported(A.id, TargetId)]) :-
    get_dict(teleport_target, N, TargetId), !,
    entity:room(A, TargetId, NA).

on_enter_trespass(W, A, N, NA, [teleported(A.id, TargetId)]) :-
    get_dict(type, N, teleporter), !,
    findall(R.id, member(R, W.rooms), RIds),
    random_member(TargetId, RIds),
    entity:room(A, TargetId, NA).

on_enter_trespass(_W, A, N, NA, [trap(A.id, Dmg) | AffEvts]) :-
    get_dict(trap, N, Dmg),
    \+ altitude(A, air),
    hp(A, Hp),
    NHp is max(0, Hp - Dmg),
    hp(A, NHp, A1),
    ( get_dict(trap_inflicts, N, Type) ->
        status:apply_aff(A1, aff{type: Type, val: Dmg, dur: 3}, NA, AffEvts)
    ;
        NA = A1, AffEvts = []
    ), !.

on_enter_trespass(_W, A, _N, A, []).
