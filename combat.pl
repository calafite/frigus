:- module(combat, [step_kill/5, step_cast/6, valid_target/3, dynamic_enemy/2]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).
:- use_module(drop).
:- use_module(status).
:- use_module(visibility).
:- use_module(stealth).

dynamic_enemy(A, T) :-
    fac(A, FA), fac(T, FT),
    ( config:enemy(FA, FT)
    ; rep_val(A, FT, Val), Val =< -20
    ; rep_val(T, FA, Val), Val =< -20
    ).

is_crime(A, T) :-
    \+ dynamic_enemy(A, T),
    fac(A, FA), FA \== criminal.

crime_check(A, T, NA) :-
    fac(T, FT),
    is_crime(A, T), !,
    fac(A, criminal, A1),
    rep_mod(A1, FT, -15, NA).
crime_check(A, _, A).

valid_target(W, A, T) :-
    alive(A), alive(T),
    visibility:can_see_target(W, A, T),
    room(T, RId),
    world:node(W, RId, N),
    \+ member(safe, N.props).

calc_dmg(A, Tag, Final) :-
    config:dmg(Tag, Base),
    config:scale(Tag, Stat, Mult),
    stat(A, Stat, Val),
    Final is Base + floor(Val * Mult).

get_aff(Tag, aff{type: Type, val: Val, dur: Dur}) :-
    config:inflicts(Tag, Type, Dur, Val), !.
get_aff(_, none).

roll_hit(A, T) :-
    stat(A, dex, DexA),
    stat(T, dex, DexT),
    random_between(1, 100, Roll),
    Chance is 90 + floor(DexA * 0.5) - floor(DexT * 0.5),
    HitChance is max(20, min(95, Chance)),
    Roll <= HitChance.

roll_crit(A, IsCrit) :-
    stat(A, dex, Dex),
    random_between(1, 100, Roll),
    Chance is 5 + floor(Dex * 0.5),
    ( Roll <= Chance -> IsCrit = true ; IsCrit = false ).

roll_double(A, IsDouble) :-
    stat(A, dex, Dex),
    affs(A, Affs),
    ( member(aff{type: haste, val: _, dur: _}, Affs) -> HMod = 25 ; HMod = 0 ),
    Chance is floor(Dex * 0.5) + HMod,
    random_between(1, 100, Roll),
    ( Roll <= Chance -> IsDouble = true ; IsDouble = false ).

step_kill(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A),
    status:can_act(A),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    crime_check(A, T, MidA),
    stealth:strip_stealth(MidA, CleanA),
    ( roll_hit(CleanA, T) ->
        wpn(CleanA, Wpn),
        calc_dmg(CleanA, Wpn, BaseDmg),
        total_armor(T, Arm),
        NetDmg is max(1, BaseDmg - Arm),
        roll_crit(CleanA, IsCrit),
        ( IsCrit == true -> Dmg1 is NetDmg * 2 ; Dmg1 = NetDmg ),
        roll_double(CleanA, IsDouble),
        ( IsDouble == true -> Dmg is Dmg1 * 2, Evt = double_hit(AId, TId, Dmg)
        ; Dmg = Dmg1, ( IsCrit == true -> Evt = crit(AId, TId, Dmg) ; Evt = hit(AId, TId, Dmg) ) ),
        get_aff(Wpn, Aff),
        apply_dmg(W, CleanA, T, Dmg, Aff, NW, Evts, Evt)
    ;
        world:update(W, CleanA, NW),
        Evts = [miss(AId, TId)]
    ).

step_cast(W, AId, Sp, TId, NW, Evts) :-
    world:entity(W, AId, A),
    status:can_act(A),
    cds(A, Cds),
    \+ get_dict(Sp, Cds, _),
    world:entity(W, TId, T),
    valid_target(W, A, T),
    config:req(Sp, ReqStat, ReqVal),
    stat(A, ReqStat, Val),
    Val >= ReqVal,
    crime_check(A, T, MidA),
    stealth:strip_stealth(MidA, CleanA),
    cost(Sp, Cost),
    mp(CleanA, Mp),
    Mp >= Cost,
    NMp is Mp - Cost,
    mp(CleanA, NMp, CastA),
    ( config:cooldown(Sp, CD) -> cds(CastA, Cds.put(Sp, CD), FinalA) ; FinalA = CastA ),
    ( roll_hit(FinalA, T) ->
        calc_dmg(FinalA, Sp, BaseDmg),
        total_armor(T, Arm),
        NetDmg is max(1, BaseDmg - Arm),
        roll_crit(FinalA, IsCrit),
        ( IsCrit == true -> Dmg is NetDmg * 2, Evt = cast_crit(AId, Sp, TId, Dmg) ; Dmg = NetDmg, Evt = cast(AId, Sp, TId, Dmg) ),
        get_aff(Sp, Aff),
        apply_dmg(W, FinalA, T, Dmg, Aff, NW, Evts, Evt)
    ;
        world:update(W, FinalA, NW),
        Evts = [cast_miss(AId, Sp, TId)]
    ).

apply_dmg(W, A, T, Dmg, _, NW, [HitEvt, dead(TId) | REvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, NTHp =< 0, !,
    hp(T, 0, NT), TId = NT.id, reward(W, A, NT, NW, REvts).
apply_dmg(W, A, T, Dmg, Aff, NW, [HitEvt | AffEvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, hp(T, NTHp, NT1),
    status:apply_aff(NT1, Aff, NT, AffEvts),
    world:update(W, A, TW), world:update(TW, NT, NW).

reward(W, A, mob{id: MId, tag: Tag} = M, NW, [xp(AId, Xp) | Evts]) :-
    config:mob_xp(Tag, Xp),
    AId = A.id,
    prog:add_xp(A, Xp, NA, ProgEvts),
    world:remove(W, MId, W1),
    world:update(W1, NA, W2),
    drop:gen_drops(W2, M, NW, DropEvts),
    append(ProgEvts, DropEvts, Evts).
reward(W, A, plyr{id: PId} = NT, NW, []) :-
    world:update(W, A, TW), world:update(TW, NT, NW).
