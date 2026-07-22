:- module(combat, [
    step_kill/5, step_cast/6, valid_target/3, dynamic_enemy/2,
    apply_dmg/8, gen_threat/5, get_highest_threat/2
]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(cfg_combat).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).
:- use_module(drop).
:- use_module(status).
:- use_module(visibility).
:- use_module(stealth).
:- use_module(social).
:- use_module(quest).
:- use_module(npc_life).

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
    fac(T, FT), is_crime(A, T), !,
    fac(A, criminal, A1), rep_mod(A1, FT, -15, NA).
crime_check(A, _, A).

valid_target(W, A, T) :-
    alive(A), alive(T), visibility:can_see_target(W, A, T),
    room(T, RId), world:node(W, RId, N), \+ member(safe, N.props).

reach_check(A, T, Wpn) :-
    altitude(A, AltA), altitude(T, AltT),
    ( AltA == AltT -> true
    ; cfg_combat:reach(Wpn, Reach), Reach >= 2 ).

get_resistance(T, Type, Res) :-
    TTag = T.tag, ( cfg_combat:resist(TTag, Type, BaseRes) -> true ; BaseRes = 1.0 ),
    ( is_dict(T, plyr) ->
        equip(T, Eq), dict_values(Eq, Items),
        findall(RVal, (
            member(Item, Items), is_dict(Item, item),
            get_dict(props, Item, Props),
            member(prop(ResistProp, RVal), Props),
            resist_prop_map(Type, ResistProp)
        ), Vals),
        sum_list(Vals, TotalMod),
        Res is max(0.0, BaseRes - (TotalMod * 0.01))
    ; Res = BaseRes ).

resist_prop_map(fire, fire_resist).
resist_prop_map(ice, ice_resist).
resist_prop_map(lightning, lightning_resist).
resist_prop_map(poison, poison_resist).
resist_prop_map(dark, dark_resist).
resist_prop_map(holy, holy_resist).

calc_comp(_, [], _, _, 0).
calc_comp(T, [dmg(Type, Amt)|Rest], Ar, Pen, Total) :-
    ( cfg_combat:physical_type(Type) -> EffAr is max(0, Ar * (1 - Pen)), Net is max(1, Amt - EffAr) ; Net = Amt ),
    TTag = T.tag,
    cfg_combat:weakness(TTag, Type, Wk),
    get_resistance(T, Type, Res),
    ( cfg_combat:immune(TTag, Type) -> Final = 0 ; Final is Net * Wk * Res ),
    calc_comp(T, Rest, Ar, Pen, RestTotal), Total is Final + RestTotal.

calc_dmg(W, A, T, Tag, Final) :-
    cfg_combat:wpn_dmg(Tag, Comps), config:scale(Tag, Stat, Mult),
    stat(A, Stat, Val), Scale is 1 + (Val * Mult * 0.05),
    scale_comps(Comps, Scale, ScaledComps),
    ( equip(A, Eq), get_dict(wpn, Eq, WObj), is_dict(WObj, item), get_dict(props, WObj, Props) ->
        findall(dmg(Type, DV), member(prop(dmg(Type), DV), Props), BonusComps),
        append(ScaledComps, BonusComps, FinalComps)
    ; FinalComps = ScaledComps ),
    total_armor(T, Ar), cfg_combat:ar_pen(Tag, Pen),
    calc_comp(T, FinalComps, Ar, Pen, Tmp),
    ( get_dict(env, W, Env) -> apply_env_dmg(Env, Tag, Tmp, Final) ; Final = Tmp ).

scale_comps([], _, []).
scale_comps([dmg(T, V)|Rest], S, [dmg(T, NV)|NRest]) :-
    NV is V * S, scale_comps(Rest, S, NRest).

apply_env_dmg(Env, Sp, Base, Final) :-
    config:spell_nature(Sp, Nature), !,
    ( Env.moon == full_moon, Nature == magic -> M1 = 1.3 ; M1 = 1.0 ),
    ( Env.weath == rain, Sp == chain_lightning -> M2 = 1.5 ; M2 = 1.0 ),
    ( Env.weath == heatwave, Nature == fire -> M3 = 1.3 ; M3 = 1.0 ),
    ( Env.weath == blizzard, Nature == ice -> M3 = 1.3 ; M3 = 1.0 ),
    Final is floor(Base * M1 * M2 * M3).
apply_env_dmg(_, _, Base, Base).

get_aff(Tag, aff{type: Type, val: Val, dur: Dur}) :- cfg_combat:inflicts(Tag, Type, Dur, Val), !.
get_aff(_, none).

roll_hit(A, T) :-
    stat(A, dex, DexA), stat(A, luk, LukA),
    stat(T, dex, DexT), stat(T, luk, LukT), random_between(1, 100, Roll),
    Chance is 85 + floor(DexA * 0.4) + floor(LukA * 0.2) - floor(DexT * 0.4) - floor(LukT * 0.2),
    ( affs(A, Affs), member(aff{type: blind, dur: _, val: _}, Affs) -> FinalChance is floor(Chance * 0.5) ; FinalChance = Chance ),
    HitChance is max(20, min(95, FinalChance)), Roll =< HitChance.

roll_dodge(T, IsDodge) :-
    stat(T, dex, Dex), stat(T, luk, Luk), random_between(1, 100, Roll),
    Chance is min(50, floor(Dex * 0.4) + floor(Luk * 0.2)), Roll =< Chance, IsDodge = true.
roll_dodge(_, false).

roll_block(T, BlockMit) :-
    equip(T, Eq), get_dict(shield, Eq, Sh), Sh \== none,
    cfg_combat:shield_block(Sh, Chance, Mit),
    stat(T, str, Str), stat(T, con, Con), random_between(1, 100, Roll),
    TotalC is Chance + floor(Str * 0.15) + floor(Con * 0.1),
    ( Roll =< TotalC -> BlockMit = Mit ; BlockMit = 0 ), !.
roll_block(_, 0).

roll_crit(A, IsCrit) :-
    stat(A, dex, Dex), stat(A, luk, Luk), random_between(1, 100, Roll),
    Chance is 5 + floor(Dex * 0.3) + floor(Luk * 0.3), Roll =< Chance, IsCrit = true.
roll_crit(_, false).

roll_double(A, IsDouble) :-
    stat(A, dex, Dex), stat(A, luk, Luk), affs(A, Affs),
    ( member(aff{type: haste, val: _, dur: _}, Affs) -> HMod = 25 ; HMod = 0 ),
    Chance is floor(Dex * 0.3) + floor(Luk * 0.2) + HMod, random_between(1, 100, Roll),
    Roll =< Chance, IsDouble = true.
roll_double(_, false).

gen_threat(W, TgtId, SrcId, Amt, NW) :-
    world:entity(W, TgtId, T),
    threats(T, Th),
    ( get_dict(SrcId, Th, Cur) -> NVal is Cur + Amt ; NVal = Amt ),
    NTh = Th.put(SrcId, NVal),
    world:update(W, T.put(threats, NTh), NW).

get_highest_threat(E, BestId) :-
    threats(E, Th), dict_pairs(Th, _, Pairs),
    sort(2, @>=, Pairs, Sorted),
    ( Sorted = [BestId-_|_] -> true ; BestId = none ).

step_kill(W, AId, TId, NW, Evts) :-
    world:entity(W, AId, A), status:can_act(A), world:entity(W, TId, T),
    valid_target(W, A, T), crime_check(A, T, MidA), stealth:strip_stealth(MidA, CleanA),
    wpn(CleanA, Wpn),
    ( config:ammo(Wpn, AmmoTag) ->
        inv(CleanA, Inv),
        ( member(stack{tag: AmmoTag, qty: Qty}, Inv), Qty >= 1 ->
            inv_rem(Inv, AmmoTag, 1, NInv), A1 = CleanA.put(inv, NInv), AmmoOK = true
        ; AmmoOK = false )
    ; A1 = CleanA, AmmoOK = true ),
    ( AmmoOK == true ->
        ( reach_check(A1, T, Wpn) ->
            ( roll_hit(A1, T) ->
                roll_dodge(T, IsDodge),
                ( IsDodge == true ->
                    world:update(W, A1, W1), Evts = [dodged(TId, AId)], try_counter(W1, T, A1, NW, Evts)
                ;
                    roll_block(T, BlockMit),
                    ( BlockMit > 0 -> BEvt = [blocked(TId, AId, BlockMit)] ; BEvt = [] ),
                    calc_dmg(W, A1, T, Wpn, BaseDmg),
                    NetDmg1 is max(0, BaseDmg - BlockMit),
                    ( NetDmg1 =:= 0 ->
                        world:update(W, A1, W1), Evts = BEvt, try_counter(W1, T, A1, NW, Evts)
                    ;
                        roll_crit(A1, IsCrit), ( IsCrit == true -> NetDmg2 is NetDmg1 * 2 ; NetDmg2 = NetDmg1 ),
                        roll_double(A1, IsDouble), affs(A1, AAffs),
                        ( IsDouble == true -> Dmg is NetDmg2 * 2, Evt = double_hit(AId, TId, Dmg)
                        ; member(aff{type: hidden, val: _, dur: _}, AAffs) -> Dmg is NetDmg2 * 3, Evt = backstab(AId, TId, Dmg)
                        ; Dmg = NetDmg2, ( IsCrit == true -> Evt = crit(AId, TId, Dmg) ; Evt = hit(AId, TId, Dmg) ) ),
                        ( is_dict(A1, mob) -> get_aff(A1.tag, Aff) ; get_aff(Wpn, Aff) ),
                        apply_dmg(W, A1, T, Dmg, Aff, W1, DEvts, Evt),
                        ( is_dict(T, mob) -> npc_life:mod_mem(W1, TId, AId, attack, W2) ; W2 = W1 ),
                        gen_threat(W2, TId, AId, Dmg, NW),
                        append(BEvt, DEvts, Evts)
                    )
                )
            ; world:update(W, A1, W1), Evts = [miss(AId, TId)], try_counter(W1, T, A1, NW, Evts) )
        ; world:update(W, A1, NW), Evts = [out_of_reach(AId, TId)] )
    ; world:update(W, CleanA, NW), Evts = [out_of_ammo(AId, Wpn)] ).

try_counter(W, T, A, NW, Evts) :-
    stat(T, dex, Dex), stat(T, luk, Luk), random_between(1, 100, Roll),
    Chance is floor(Dex * 0.2) + floor(Luk * 0.1),
    ( Roll =< Chance ->
        wpn(T, TWpn), calc_dmg(W, T, A, TWpn, Dmg),
        apply_dmg(W, T, A, Dmg, none, NW, CEvts, counterattack(T.id, A.id, Dmg)),
        append(Evts, CEvts, _)
    ; NW = W ).

step_cast(W, AId, Sp, _, NW, Evts) :-
    cfg_combat:aoe(Sp), !,
    world:entity(W, AId, A), status:can_cast(A), cds(A, Cds), \+ get_dict(Sp, Cds, _),
    config:req(Sp, ReqStat, ReqVal), stat(A, ReqStat, Val), Val >= ReqVal,
    stealth:strip_stealth(A, CleanA), cost(Sp, Cost), mp(CleanA, Mp), Mp >= Cost,
    NMp is Mp - Cost, mp(CleanA, NMp, CastA),
    ( config:cooldown(Sp, CD) -> cds(CastA, Cds.put(Sp, CD), FinalA) ; FinalA = CastA ),
    room(FinalA, RId), world:room_entities(W, RId, Ents),
    apply_aoe(W, FinalA, Sp, Ents, W1, AoeEvts),
    world:update(W1, FinalA, NW),
    Evts = [cast_aoe(AId, Sp) | AoeEvts].

step_cast(W, AId, Sp, _, NW, Evts) :-
    cfg_combat:summon(Sp, MobTag), !,
    world:entity(W, AId, A), status:can_cast(A), cds(A, Cds), \+ get_dict(Sp, Cds, _),
    config:req(Sp, ReqStat, ReqVal), stat(A, ReqStat, Val), Val >= ReqVal,
    stealth:strip_stealth(A, CleanA), cost(Sp, Cost), mp(CleanA, Mp), Mp >= Cost,
    NMp is Mp - Cost, mp(CleanA, NMp, CastA),
    ( config:cooldown(Sp, CD) -> cds(CastA, Cds.put(Sp, CD), FinalA) ; FinalA = CastA ),
    room(FinalA, RId),
    random_between(100000, 999999, Rnd), atomic_list_concat([MobTag, '_', Rnd], MId),
    lvl(FinalA, Lvl),
    BaseHp is 20 + (Lvl * 10), BaseStr is 10 + (Lvl * 2), BaseDex is 10 + (Lvl * 2), BaseInt is 10 + (Lvl * 2),
    Mob = mob{id: MId, tag: MobTag, name: MobTag, lvl: Lvl, hp: BaseHp, max_hp: BaseHp, str: BaseStr, dex: BaseDex, int: BaseInt, room: RId, props: [], master: AId, fac: FinalA.fac, threats: dict{}},
    world:add(W, mob, Mob, W1),
    world:update(W1, FinalA, NW),
    Evts = [summoned(AId, Sp, MId)].

step_cast(W, AId, Sp, TId, NW, Evts) :-
    world:entity(W, AId, A), status:can_cast(A), cds(A, Cds), \+ get_dict(Sp, Cds, _),
    world:entity(W, TId, T), valid_target(W, A, T), config:req(Sp, ReqStat, ReqVal),
    stat(A, ReqStat, Val), Val >= ReqVal, crime_check(A, T, MidA),
    stealth:strip_stealth(MidA, CleanA), cost(Sp, Cost), mp(CleanA, Mp), Mp >= Cost,
    NMp is Mp - Cost, mp(CleanA, NMp, CastA),
    ( config:cooldown(Sp, CD) -> cds(CastA, Cds.put(Sp, CD), FinalA) ; FinalA = CastA ),
    ( reach_check(FinalA, T, Sp) ->
        ( roll_hit(FinalA, T) ->
            calc_dmg(W, FinalA, T, Sp, BaseDmg), total_armor(T, Arm), NetDmg is max(1, BaseDmg - Arm),
            roll_crit(FinalA, IsCrit),
            ( IsCrit == true -> Dmg is NetDmg * 2, Evt = cast_crit(AId, Sp, TId, Dmg) ; Dmg = NetDmg, Evt = cast(AId, Sp, TId, Dmg) ),
            get_aff(Sp, Aff), apply_dmg(W, FinalA, T, Dmg, Aff, W1, DEvts, Evt),
            ( is_dict(T, mob) -> npc_life:mod_mem(W1, TId, AId, attack, W2) ; W2 = W1 ),
            gen_threat(W2, TId, AId, Dmg, NW), Evts = DEvts
        ; world:update(W, FinalA, NW), Evts = [cast_miss(AId, Sp, TId)] )
    ; world:update(W, FinalA, NW), Evts = [out_of_reach(AId, TId)] ).

apply_aoe(W, _, _, [], W, []).
apply_aoe(W, A, Sp, [T|Ts], NW, Evts) :-
    ( A.id \== T.id, alive(T), (is_dict(T, plyr) ; is_dict(T, mob)),
      (cfg_combat:friendly_fire_enabled(Sp) ; dynamic_enemy(A, T)) ->
        ( roll_hit(A, T) ->
            calc_dmg(W, A, T, Sp, BaseDmg), total_armor(T, Arm), NetDmg is max(1, BaseDmg - Arm),
            roll_crit(A, IsCrit),
            ( IsCrit == true -> Dmg is NetDmg * 2 ; Dmg = NetDmg ),
            get_aff(Sp, Aff), apply_dmg(W, A, T, Dmg, Aff, W1, DEvts, hit_aoe(A.id, T.id, Dmg)),
            ( is_dict(T, mob) -> npc_life:mod_mem(W1, T.id, A.id, attack, W2) ; W2 = W1 ),
            gen_threat(W2, T.id, A.id, Dmg, W3),
            Evt = DEvts
        ; W3 = W, Evt = [aoe_miss(A.id, T.id)] )
    ; W3 = W, Evt = [] ),
    apply_aoe(W3, A, Sp, Ts, NW, REvts),
    append(Evt, REvts, Evts).

apply_dmg(W, A, T, Dmg, _, NW, [HitEvt, reborn(TId) | REvts], HitEvt) :-
    get_dict(tag, T, phoenix), get_dict(rebirth, T, true), hp(T, THp), NTHp is THp - Dmg, NTHp =< 0, !,
    get_dict(max_hp, T, Max), NHp is floor(Max * 0.5), TId = T.id,
    T1 = T.put(hp, NHp).put(rebirth, false),
    world:update(W, A, TW), world:update(TW, T1, NW), REvts = [].

apply_dmg(W, A, T, Dmg, _, NW, [HitEvt, dead(TId) | REvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, NTHp =< 0, !,
    hp(T, 0, NT), TId = NT.id, reward(W, A, NT, NW, REvts).

apply_dmg(W, A, T, Dmg, Aff, NW, [HitEvt | AffEvts], HitEvt) :-
    hp(T, THp), NTHp is THp - Dmg, hp(T, NTHp, NT1),
    status:apply_aff(NT1, Aff, NT2, BaseAffEvts),
    ( get_dict(tag, A, basilisk), alive(NT2) ->
        stat(A, luk, Luk), random_between(1, 100, Roll),
        ( Roll =< 30 + floor(Luk * 0.2) -> status:apply_aff(NT2, aff{type: stun, val: 0, dur: 1}, NT, GazeEvts),
          append(BaseAffEvts, [gaze_stun(A.id, T.id) | GazeEvts], AffEvts)
        ; NT = NT2, AffEvts = BaseAffEvts )
    ; NT = NT2, AffEvts = BaseAffEvts ),
    world:update(W, A, TW), world:update(TW, NT, NW).

reward(W, A, mob{id: MId, tag: Tag} = M, NW, Evts) :-
    config:mob_xp(Tag, Xp), world:remove(W, MId, W1),
    ( get_dict(party, A, PId), PId \== none ->
        social:party_reward(W1, PId, A.room, Tag, Xp, W2, XpEvts)
    ; quest:update_kill(A, Tag, QA, QEvts), prog:add_xp(QA, Xp, NA, PEvts),
      world:update(W1, NA, W2), append(QEvts, PEvts, XpEvts) ),
    drop:gen_drops(W2, A, M, NW, DropEvts), append(XpEvts, DropEvts, Evts).
reward(W, A, plyr{id: PId} = NT, NW, [respawn(PId, SpawnRId) | Evts]) :-
    prog:rebirth_player(NT, RebornPlayer, SpawnRId),
    world:update(W, A, TW), world:update(TW, RebornPlayer, NW), Evts = [].
