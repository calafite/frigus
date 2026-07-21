:- module(status, [step_tick/4, can_act/1, apply_aff/4]).

:- use_module(entity).
:- use_module(world).

can_act(E) :-
    affs(E, A),
    \+ member(aff{type: stun, dur: _, val: _}, A),
    \+ member(aff{type: freeze, dur: _, val: _}, A).

apply_aff(E, none, E, []) :- !.
apply_aff(E, Aff, NE, [inflicted(E.id, Aff.type)]) :-
    affs(E, A),
    ( select(aff{type: Aff.type, stat: _, val: _, dur: _}, A, R) -> NA = [Aff|R]
    ; select(aff{type: Aff.type, val: _, dur: _}, A, R) -> NA = [Aff|R]
    ; NA = [Aff|A] ),
    affs(E, NA, NE).

step_tick(W, Id, NW, Evts) :-
    world:entity(W, Id, E),
    affs(E, A),
    tick_affs(E, A, NA, Dmg, TEvts),
    hp(E, Hp),
    props(E, P),
    ( member(regen, P) ->
        get_dict(max_hp, E, MaxHp),
        Regen is floor(MaxHp * 0.1),
        TmpHp is min(MaxHp, Hp + Regen)
    ;
        TmpHp = Hp
    ),
    NHp is max(0, TmpHp - Dmg),
    hp(E, NHp, E1),
    affs(E1, NA, E2),
    cds(E2, Cds),
    dec_cds(Cds, NCds),
    cds(E2, NCds, NE),
    ( NHp =:= 0 ->
        Evts = [dead(Id)|TEvts],
        world:remove(W, Id, NW)
    ;
        Evts = TEvts,
        world:update(W, NE, NW)
    ).

dec_cds(Cds, NCds) :-
    dict_pairs(Cds, cds, Pairs),
    dec_pairs(Pairs, NPairs),
    dict_pairs(NCds, cds, NPairs).

dec_pairs([], []).
dec_pairs([_-V|T], NT) :- V =< 1, !, dec_pairs(T, NT).
dec_pairs([K-V|T], [K-NV|NT]) :- NV is V - 1, dec_pairs(T, NT).

is_immune(E, burn) :- props(E, P), member(fire_immune, P).
is_immune(_, _).

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
aff_dmg(aff{type: bloodline_curse, val: V, dur: _}, V, tick(bloodline_curse, V)) :- !.
aff_dmg(aff{type: buff, stat: S, val: V, dur: _}, 0, tick(buff(S), V)) :- !.
aff_dmg(aff{type: T, val: _, dur: _}, 0, tick(T, 0)).
