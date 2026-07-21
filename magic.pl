:- module(magic, [step_cast/6]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(combat).
:- use_module(status).
:- use_module(stealth).

allowed_cast(A, Sp) :-
    ( config:req_race(Sp, Race) ->
        entity:race(A, Race)
    ; true ).

prepare_cast(A, Sp, CastA) :-
    config:cost(Sp, Cost),
    mp(A, Mp), Mp >= Cost,
    NMp is Mp - Cost,
    mp(A, NMp, A1),
    cds(A1, Cds),
    ( config:cooldown(Sp, CD) -> cds(A1, Cds.put(Sp, CD), CastA) ; CastA = A1 ).

step_cast(W, Id, Sp, TId, NW, Evts) :-
    world:entity(W, Id, A),
    status:can_act(A),
    allowed_cast(A, Sp),
    config:req(Sp, ReqStat, ReqVal),
    stat(A, ReqStat, Val), Val >= ReqVal,
    cds(A, Cds), \+ get_dict(Sp, Cds, _),
    prepare_cast(A, Sp, CastA),
    config:spell_nature(Sp, Nature),
    cast_nature(Nature, W, CastA, Sp, TId, NW, Evts).

cast_nature(damage, W, A, Sp, TId, NW, Evts) :-
    world:entity(W, TId, T),
    combat:valid_target(W, A, T),
    combat:crime_check(A, T, MidA),
    stealth:strip_stealth(MidA, CleanA),
    ( combat:roll_hit(CleanA, T) ->
        combat:calc_dmg(CleanA, Sp, BaseDmg),
        total_armor(T, Arm),
        NetDmg is max(1, BaseDmg - Arm),
        combat:roll_crit(CleanA, IsCrit),
        ( IsCrit == true -> Dmg is NetDmg * 2, Evt = cast_crit(A.id, Sp, TId, Dmg)
        ; Dmg = NetDmg, Evt = cast(A.id, Sp, TId, Dmg) ),
        combat:get_aff(Sp, Aff),
        combat:apply_dmg(W, CleanA, T, Dmg, Aff, NW, Evts, Evt)
    ;
        world:update(W, CleanA, NW),
        Evts = [cast_miss(A.id, Sp, TId)]
    ).

cast_nature(healing, W, A, Sp, TId, NW, [healed(AId, TId, Amt) | AffEvts]) :-
    AId = A.id,
    world:entity(W, TId, T),
    alive(T),
    room(A, RId), room(T, RId),
    combat:calc_dmg(A, Sp, Amt),
    hp(T, Hp), get_dict(max_hp, T, MaxHp),
    NHp is min(MaxHp, Hp + Amt),
    hp(T, NHp, T1),
    combat:get_aff(Sp, Aff),
    status:apply_aff(T1, Aff, NT, AffEvts),
    world:update(W, A, TW),
    world:update(TW, NT, NW).

cast_nature(buff, W, A, Sp, TId, NW, AffEvts) :-
    world:entity(W, TId, T),
    alive(T),
    room(A, RId), room(T, RId),
    combat:get_aff(Sp, Aff),
    status:apply_aff(T, Aff, NT, AffEvts),
    world:update(W, A, TW),
    world:update(TW, NT, NW).

cast_nature(necromancy, W, A, Sp, _, NW, [summoned(AId, MinionId)]) :-
    AId = A.id,
    room(A, RId),
    random_between(10000, 99999, Rnd),
    format(atom(MinionId), 'skeleton_~w', [Rnd]),
    Minion = mob{
        id: MinionId,
        tag: skeleton,
        fac: AId,
        room: RId,
        hp: 30,
        max_hp: 30,
        str: 10,
        dex: 8,
        int: 1,
        props: [undead]
    },
    world:add(W, mob, Minion, TW),
    world:update(TW, A, NW).

cast_nature(cataclysm, W, A, Sp, _, NW, [cataclysm(AId, Sp) | AllEvts]) :-
    AId = A.id,
    room(A, RId),
    world:room_entities(W, RId, Ents),
    combat:get_aff(Sp, Aff),
    select(A, Ents, Targets),
    apply_cataclysm(W, A, Sp, Targets, Aff, NW, AllEvts).

apply_cataclysm(W, _, _, [], _, W, []).
apply_cataclysm(W, A, Sp, [T|Ts], Aff, NW, AllEvts) :-
    ( (is_dict(T, plyr) ; is_dict(T, mob)), alive(T) ->
        combat:calc_dmg(A, Sp, BaseDmg),
        total_armor(T, Arm),
        Dmg is max(1, BaseDmg - Arm),
        HitEvt = cast(A.id, Sp, T.id, Dmg),
        combat:apply_dmg(W, A, T, Dmg, Aff, TW, Evts, HitEvt),
        world:entity(TW, A.id, NA),
        apply_cataclysm(TW, NA, Sp, Ts, Aff, NW, RestEvts),
        append(Evts, RestEvts, AllEvts)
    ;
        apply_cataclysm(W, A, Sp, Ts, Aff, NW, AllEvts)
    ).
