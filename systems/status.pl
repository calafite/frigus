:- module(status, [do_tick/2, is_cced/2, do_respawn/2]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('combat').

is_cced(Ent, CC) :-
    ( entity:has_aff(Ent, stunned) -> CC = stunned
    ; entity:has_aff(Ent, frozen) -> CC = frozen
    ; entity:has_aff(Ent, paralysed) -> CC = paralysed
    ).

do_respawn(Id, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(hp, Actor, Hp), Hp =< 0, !,
    get_dict(max_hp, Actor, MaxHp), get_dict(max_mp, Actor, MaxMp),
    Reborn = Actor.put(hp, MaxHp).put(mp, MaxMp).put(room, square).put(affs, dict{}),
    world:put_entity(Reborn),
    Evts = [respawned(Id, square)].
do_respawn(Id, [error(cannot_respawn_alive(Id))]).

do_tick(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
        tick_regen(Actor, Act1, RegenEvts),
        tick_cds(Act1, Act2),
        tick_affs(Act2, Act3, AffEvts),
        ( entity:is_alive(Act3) ->
            world:put_entity(Act3),
            append(RegenEvts, AffEvts, Evts)
        ;
            combat:resolve_death(environment, Act3, DeathEvts),
            get_dict(id, Act3, TgtId),
            ( get_dict(name, Act3, TgtName) -> true ; TgtName = TgtId ),
            append(RegenEvts, AffEvts, TmpEvts),
            append(TmpEvts, [dead(TgtId, TgtName) | DeathEvts], Evts)
        )
    ; Evts = [] ).

regen_mult(Act, HpMult, MpMult) :-
    ( entity:has_trait(Act, troll_regen) -> HpMult1 = 4.0
    ; entity:has_trait(Act, high_regen)  -> HpMult1 = 2.0
    ; HpMult1 = 1.0 ),
    ( entity:has_trait(Act, keen_mind)   -> MpMult1 = 1.8
    ; MpMult1 = 1.0 ),
    HpMult = HpMult1, MpMult = MpMult1.

tick_regen(Act, NAct, Evts) :-
    ( get_dict(cds, Act, Cds), get_dict(combat, Cds, CCd), CCd > 0 ->
        NAct = Act, Evts = []
    ;
        ( get_dict(hp, Act, Hp) -> true ; Hp = 50 ),
        ( get_dict(max_hp, Act, MaxHp) -> true ; MaxHp = 50 ),
        ( get_dict(mp, Act, Mp) -> true ; Mp = 20 ),
        ( get_dict(max_mp, Act, MaxMp) -> true ; MaxMp = 20 ),

        entity:get_stat(Act, con, Con), entity:get_stat(Act, wis, Wis),
        regen_mult(Act, HpMult, MpMult),
        BaseHp is 2 + floor(Con * 0.2), BaseMp is 2 + floor(Wis * 0.2),
        HpRegen is floor(BaseHp * HpMult), MpRegen is floor(BaseMp * MpMult),

        ( Hp < MaxHp -> NHp is min(MaxHp, Hp + HpRegen) ; NHp = Hp ),
        ( Mp < MaxMp -> NMp is min(MaxMp, Mp + MpRegen) ; NMp = Mp ),

        NAct = Act.put(hp, NHp).put(mp, NMp),
        ( (Hp \== NHp ; Mp \== NMp) ->
            get_dict(id, Act, ActId), Evts = [regenerated(ActId, NHp, NMp)]
        ; Evts = [] )
    ).

tick_cds(Act, NAct) :-
    ( get_dict(cds, Act, Cds) -> true ; Cds = dict{} ),
    dict_pairs(Cds, Tag, Pairs), dec_pairs(Pairs, NPairs),
    dict_pairs(NCds, Tag, NPairs), NAct = Act.put(cds, NCds).

dec_pairs([], []).
dec_pairs([_-V|T], NT) :- V =< 1, !, dec_pairs(T, NT).
dec_pairs([K-V|T], [K-NV|NT]) :- NV is V - 1, dec_pairs(T, NT).

tick_affs(Act, NAct, Evts) :-
    ( get_dict(affs, Act, Affs) -> dict_pairs(Affs, _, Pairs) ; Pairs = [] ),
    process_aff_pairs(Pairs, Act, NAct, Evts).

process_aff_pairs([], Act, Act, []).
process_aff_pairs([AffTag-AffNode|Rest], Act, FinalAct, Evts) :-
    get_dict(dur, AffNode, Dur), get_dict(mag, AffNode, Mag),
    NDur is Dur - 1,
    ( is_dot(AffTag) ->
        entity:mod_hp(Act, -Mag, Act1), get_dict(id, Act1, AId), TickEvt = [aff_tick(AId, AffTag, Mag)]
    ; Act1 = Act, TickEvt = [] ),
    get_dict(id, Act1, AId2),
    ( NDur =< 0 ->
        entity:remove_aff(Act1, AffTag, Act2), FadeEvt = [aff_faded(AId2, AffTag)]
    ;
        NAffNode = AffNode.put(dur, NDur), get_dict(affs, Act1, CurAffs),
        NAffs = CurAffs.put(AffTag, NAffNode), Act2 = Act1.put(affs, NAffs), FadeEvt = []
    ),
    process_aff_pairs(Rest, Act2, FinalAct, RestEvts),
    append(TickEvt, FadeEvt, E1), append(E1, RestEvts, Evts).

is_dot(poisoned).
is_dot(bleeding).
is_dot(burning).
is_dot(frostbite).
is_dot(soul_rot).
is_dot(holy_fire).
is_dot(venom).
