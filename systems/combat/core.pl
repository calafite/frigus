:- module(combat_core, [
              to_atom/2, roll_dice/3, get_display_name/2, get_weapon_tag/2,
              get_env_mods/6, chk_dodge/2, calc_mitigation/3, calc_spell_mitigation/3,
              chk_melee_crit/4, chk_spell_crit/5, calc_melee_raw/5, chk_flurry/2,
              apply_affliction_list/3, extract_aff_tags/2, aff_event/3,
              has_active_summon/1
                       ]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('../../config/combat').
:- use_module('../status').
:- use_module(library(random)).
:- use_module(library(lists)).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

roll_dice(Min, Max, Val) :- random_between(Min, Max, Val).

get_display_name(Ent, Name) :-
    is_dict(Ent),
    ( get_dict(name, Ent, RawName), RawName \== "" -> Name = RawName
    ; (is_dict(Ent, plyr) ; get_dict(tag, Ent, player)) -> get_dict(id, Ent, Name)
    ; get_dict(tag, Ent, RawTag), RawTag \== "" -> to_atom(RawTag, Name)
    ; get_dict(id, Ent, Name) -> true
    ; Name = unknown ), !.
get_display_name(RawId, Name) :-
    to_atom(RawId, Id),
    ( world:get_entity(Id, Ent) -> get_display_name(Ent, Name) ; Name = Id ).

get_weapon_tag(Ent, WTag) :-
    ( get_dict(equip, Ent, Eq), is_dict(Eq), get_dict(wpn, Eq, Raw), Raw \== none -> to_atom(Raw, WTag)
    ; get_dict(tag, Ent, RawTag) -> to_atom(RawTag, WTag)
    ; WTag = fists ).

get_env_mods(Actor, RoomId, Env, MagicMult, CorrMult, MoonMult) :-
    ( world:get_room(RoomId, Room), get_dict(env, Room, REnv) ->
          ( get_dict(magic, REnv, AmbientMagic) -> true ; AmbientMagic = 10 ),
          ( get_dict(corr, REnv, Corruption) -> true ; Corruption = 0 )
    ; AmbientMagic = 10, Corruption = 0 ),

    MagicMult is 1.0 + (AmbientMagic / 100),
    ( get_dict(race, Actor, Race) -> true ; Race = unknown ),

    ( member(Race, [angel, high_elf]) -> CorrMult is max(0.1, 1.0 - (Corruption / 200))
    ; member(Race, [demon, dark_elf]) -> CorrMult is 1.0 + (Corruption / 100)
    ; CorrMult = 1.0 ),

    ( is_dict(Actor, mob) ->
          ( get_dict(moon, Env, Moon) -> true ; Moon = full_moon ),
          moon_mob_mult(Moon, MoonMult)
    ; MoonMult = 1.0 ).

moon_mob_mult(new_moon, 0.8).
moon_mob_mult(crescent, 0.9).
moon_mob_mult(half, 1.0).
moon_mob_mult(gibbous, 1.1).
moon_mob_mult(full_moon, 1.3).

chk_dodge(Src, Tgt) :-
    \+ status:is_rooted(Tgt, _),
    entity:get_stat(Tgt, dex, TDex), entity:get_stat(Tgt, luk, TLuk), entity:get_stat(Src, dex, SDex),
    ( entity:has_trait(Tgt, elusive) -> Bonus1 = 20 ; entity:has_trait(Tgt, quick) -> Bonus1 = 10 ; Bonus1 = 0 ),
    Rate is max(0, min(65, floor((TDex * 1.2 + TLuk * 0.5) - (SDex * 0.6)) + Bonus1)),
    roll_dice(1, 100, Roll), Roll =< Rate.

calc_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, con, TCon), Red is floor(TCon * 0.25), Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, fortified, dict{mag: FMag}) -> FMult = (100 - FMag)/100 ; FMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * FMult * DMult)).

calc_spell_mitigation(Tgt, RawDmg, FinalDmg) :-
    entity:get_stat(Tgt, wis, TWis), Red is floor(TWis * 0.25), Final1 is max(1, RawDmg - Red),
    ( entity:get_aff(Tgt, magic_barrier, dict{mag: MMag}) -> MMult = (100 - MMag)/100 ; MMult = 1.0 ),
    ( entity:get_aff(Tgt, divine_protection, dict{mag: DMag}) -> DMult = (100 - DMag)/100 ; DMult = 1.0 ),
    ( entity:get_aff(Tgt, fortified, dict{mag: FMag}) -> FMult = (100 - FMag)/100 ; FMult = 1.0 ),
    FinalDmg is max(1, floor(Final1 * MMult * DMult * FMult)).

chk_melee_crit(Src, WTag, IsCrit, FinalMult) :-
    entity:get_stat(Src, str, SStr), entity:get_stat(Src, luk, SLuk),
    ( combat_config:wpn_trait(WTag, precision) -> Prec = 15 ; Prec = 0 ),
    ( entity:has_trait(Src, feral) -> Feral = 15 ; Feral = 0 ),
    Rate is max(5, min(85, floor(SStr * 0.4 + SLuk * 0.5 + Prec + Feral))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate -> IsCrit = true, combat_config:wpn_crit_mult(WTag, BaseMult),
                      ( entity:has_trait(Src, celestial) -> FinalMult is BaseMult * 1.5 ; FinalMult = BaseMult )
    ; IsCrit = false, FinalMult = 1.0 ).

is_holy_spell(last_judgement, _).
is_holy_spell(smite, _).
is_holy_spell(divine_retribution, _).
is_holy_spell(_, Src) :- entity:has_trait(Src, celestial).

chk_spell_crit(Src, Sp, Tgt, IsCrit, Mult) :-
    is_holy_spell(Sp, Src), entity:has_aff(Tgt, marked), !,
    IsCrit = true,
    ( entity:has_trait(Src, celestial) -> Mult = 2.5 ; Mult = 2.0 ).

chk_spell_crit(Src, _Sp, _Tgt, IsCrit, Mult) :-
    entity:get_stat(Src, int, SInt), entity:get_stat(Src, wis, SWis), entity:get_stat(Src, luk, SLuk),
    Rate is max(5, min(75, floor(SInt * 0.3 + SWis * 0.3 + SLuk * 0.4))),
    roll_dice(1, 100, Roll),
    ( Roll =< Rate -> IsCrit = true, Mult = 1.8 ; IsCrit = false, Mult = 1.0 ).

calc_melee_raw(Src, RoomId, EnvState, WTag, RawDmg) :-
    ( combat_config:wpn_dmg(WTag, [dmg(_, Base)|_]) -> true ; Base = 4 ),
    entity:get_stat(Src, str, Str),
    ( combat_config:wpn_trait(WTag, reliable) -> roll_dice(3, 6, Var) ; roll_dice(1, 10, Var) ),
    get_env_mods(Src, RoomId, EnvState, _, CorrMult, MoonMult),
    Raw1 is Base + Var + floor(Str * 0.4),
    ( entity:get_aff(Src, bloodlust, dict{mag: BMag}) -> BMult = (100 + BMag)/100 ; BMult = 1.0 ),
    ( entity:get_aff(Src, weakened, dict{mag: WMag}) -> WMult = (100 - WMag)/100 ; WMult = 1.0 ),
    ( entity:get_aff(Src, stealthed, dict{mag: SMag}) -> SMult = (SMag)/100 ; SMult = 1.0 ), % Apply stealth multiplier
    RawDmg is floor(Raw1 * BMult * WMult * CorrMult * MoonMult * SMult).

chk_flurry(Src, WTag) :-
    ( combat_config:wpn_trait(WTag, flurry) ; entity:has_trait(Src, quick) ),
    entity:get_stat(Src, dex, SDex), entity:get_stat(Src, luk, SLuk),
    Rate is max(10, min(60, floor(SDex * 0.6 + SLuk * 0.3))),
    roll_dice(1, 100, Roll), Roll =< Rate.

apply_affliction_list(Ent, [], Ent).
apply_affliction_list(Ent, [Aff|Rest], NEnt) :-
    Aff =.. [AffTag, Dur, Mag], entity:apply_aff(Ent, AffTag, Dur, Mag, TmpEnt),
    apply_affliction_list(TmpEnt, Rest, NEnt).

extract_aff_tags([], []).
extract_aff_tags([Aff|Rest], [Tag|TRest]) :- Aff =.. [Tag, _, _], extract_aff_tags(Rest, TRest).

aff_event(TgtName, Tag, aff_applied(TgtName, Tag)).

has_active_summon(OwnerId) :-
    world:all_mobs(Mobs),
    member(M, Mobs),
    get_dict(owner, M, OwnerId),
    entity:is_alive(M), !.
