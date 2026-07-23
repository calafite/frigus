:- module(status, [do_tick/2]).

:- use_module('../core/world').
:- use_module('../core/entity').

do_tick(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
        tick_regen(Actor, Act1, RegenEvts),
        tick_cds(Act1, Act2),
        tick_affs(Act2, ActFinal, AffEvts),

        world:put_entity(ActFinal),
        append(RegenEvts, AffEvts, Evts)
    ;
        Evts = []
    ).

tick_regen(Act, NAct, Evts) :-
    ( get_dict(hp, Act, Hp) -> true ; Hp = 50 ),
    ( get_dict(max_hp, Act, MaxHp) -> true ; MaxHp = 50 ),
    ( get_dict(mp, Act, Mp) -> true ; Mp = 20 ),
    ( get_dict(max_mp, Act, MaxMp) -> true ; MaxMp = 20 ),
    entity:get_stat(Act, con, Con),
    entity:get_stat(Act, wis, Wis),
    HpRegen is 2 + floor(Con * 0.2),
    MpRegen is 2 + floor(Wis * 0.2),
    ( Hp < MaxHp -> NHp is min(MaxHp, Hp + HpRegen) ; NHp = Hp ),
    ( Mp < MaxMp -> NMp is min(MaxMp, Mp + MpRegen) ; NMp = Mp ),
    NAct = Act.put(hp, NHp).put(mp, NMp),
    ( (Hp \== NHp ; Mp \== NMp) ->
        get_dict(id, Act, ActId),
        Evts = [regenerated(ActId, NHp, NMp)]
    ;
        Evts = []
    ).

tick_cds(Act, NAct) :-
    get_dict(cds, Act, Cds),
    dict_pairs(Cds, Tag, Pairs),
    dec_pairs(Pairs, NPairs),
    dict_pairs(NCds, Tag, NPairs),
    NAct = Act.put(cds, NCds).

dec_pairs([], []).
dec_pairs([_-V|T], NT) :- V =< 1, !, dec_pairs(T, NT).
dec_pairs([K-V|T], [K-NV|NT]) :- NV is V - 1, dec_pairs(T, NT).

tick_affs(Act, Act, []).
