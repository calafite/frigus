:- module(status, [step_tick/4, can_act/1, can_cast/1, apply_aff/4]).

:- use_module(entity).
:- use_module(world).
:- use_module(env).
:- use_module(survival).
:- use_module(simulation).
:- use_module(library(random)).
:- use_module(library(lists)).

can_act(E) :-
    affs(E, A),
    \+ member(aff{type: stun, dur: _, val: _}, A),
    \+ member(aff{type: freeze, dur: _, val: _}, A),
    get_dict(state, E, State), State \== sleeping,
    ( member(aff{type: confusion, dur: _, val: _}, A) -> random_between(1, 100, R), R > 50 ; true ).

can_cast(E) :-
    can_act(E),
    affs(E, A),
    \+ member(aff{type: silence, dur: _, val: _}, A).

apply_aff(E, none, E, []) :- !.
apply_aff(E, Aff, NE, [inflicted(E.id, Aff.type)]) :-
    affs(E, A),
    ( select(aff{type: Aff.type, stat: _, val: _, dur: _}, A, R) -> NA = [Aff|R]
    ; select(aff{type: Aff.type, val: _, dur: _}, A, R) -> NA = [Aff|R]
    ; NA = [Aff|A] ),
    affs(E, NA, NE).

step_tick(W, system, NW, Evts) :- !,
    env:tick_env(W, W1, Evts1),
    simulation:tick_simulation(W1, NW, Evts2),
    append(Evts1, Evts2, Evts).

step_tick(W, Id, NW, Evts) :-
    world:entity(W, Id, E),
    ( is_dict(E, plyr) ->
        survival:tick_srv(W, Id, E, E1, SEvts)
    ; E1 = E, SEvts = [] ),
    affs(E1, A),
    tick_affs(E1, A, NA, Dmg, TEvts),
    hp(E1, Hp),
    props(E1, P),
    ( member(regen, P) ->
        get_dict(max_hp, E1, MaxHp),
        Regen is floor(MaxHp * 0.1),
        TmpHp is min(MaxHp, Hp + Regen)
    ; TmpHp = Hp ),
    room(E1, RId), world:node(W, RId, N),
    ( member(burning(I), N.props), \+ is_immune(E1, burn) ->
        FDmg is I * 4,
        NHp is max(0, TmpHp - FDmg - Dmg),
        FEvt = [fire_burn(Id, FDmg)]
    ;
        NHp is max(0, TmpHp - Dmg),
        FEvt = []
    ),
    hp(E1, NHp, E2),
    affs(E2, NA, E3),
    cds(E3, Cds),
    dec_cds(Cds, NCds),
    cds(E3, NCds, NE),
    ( NHp =:= 0 ->
        append([dead(Id)|TEvts], SEvts, AllEvts1),
        append(AllEvts1, FEvt, AllEvts),
        Evts = AllEvts,
        world:remove(W, Id, NW)
    ; append(TEvts, SEvts, TmpEvts),
      append(TmpEvts, FEvt, Evts),
      world:update(W, NE, NW) ).

dec_cds(Cds, NCds) :-
    dict_pairs(Cds, cds, Pairs),
    dec_pairs(Pairs, NPairs),
    dict_pairs(NCds, cds, NPairs).

dec_pairs([], []).
dec_pairs([_-V|T], NT) :- V =< 1, !, dec_pairs(T, NT).
dec_pairs([K-V|T], [K-NV|NT]) :- NV is V - 1, dec_pairs(T, NT).

is_immune(E, burn) :- props(E, P), member(fire_immune, P).
is_immune(E, poison) :- props(E, P), member(poison_immune, P).
is_immune(E, bleed) :- props(E, P), member(bloodless, P).
is_immune(E, freeze) :- props(E, P), member(cold_immune, P).
is_immune(_, _) :- fail.

tick_affs(_, [], [], 0, []).
tick_affs(E, [A|T], NT, Dmg, Evts) :-
    is_immune(E, A.type), !,
    tick_affs(E, T, NT, Dmg, Evts).
tick_affs(E, [A|T], NT, Dmg, Evts) :-
    A.dur =< 1,
    aff_dmg(A, ADmg, Evt),
    tick_affs(E, T, RestA, RestDmg, RestEvts),
    NT = RestA, Dmg is ADmg + RestDmg, Evts = [Evt, exp(A.type)|RestEvts].
tick_affs(E, [A|T], [NA|NT], Dmg, Evts) :-
    A.dur > 1,
    NA = A.put(dur, A.dur - 1),
    aff_dmg(A, ADmg, Evt),
    tick_affs(E, T, NT, RestDmg, RestEvts),
    Dmg is ADmg + RestDmg, Evts = [Evt|RestEvts].

aff_dmg(aff{type: poison, val: V, dur: _}, V, tick(poison, V)) :- !.
aff_dmg(aff{type: burn, val: V, dur: _}, V, tick(burn, V)) :- !.
aff_dmg(aff{type: bleed, val: V, dur: _}, V, tick(bleed, V)) :- !.
aff_dmg(aff{type: bloodline_curse, val: V, dur: _}, V, tick(bloodline_curse, V)) :- !.
aff_dmg(aff{type: plague, val: _, dur: _}, 2, tick(plague, 2)) :- !.
aff_dmg(aff{type: fever, val: _, dur: _}, 3, tick(fever, 3)) :- !.
aff_dmg(aff{type: blight, val: _, dur: _}, 4, tick(blight, 4)) :- !.
aff_dmg(aff{type: buff, stat: S, val: V, dur: _}, 0, tick(buff(S), V)) :- !.
aff_dmg(aff{type: T, val: _, dur: _}, 0, tick(T, 0)).
