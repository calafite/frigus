:- module(stealth, [step_hide/4, strip_stealth/2, step_disguise/4]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(env).

step_hide(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    room(A, RId), world:node(W, RId, N),
    ( member(dark, N.props) -> LightBonus = 15
    ; member(originally_dark, N.props) -> LightBonus = 5
    ; LightBonus = -10 ),
    ( env:db_env(Env) ->
        ( member(Env.weath, [storm, blizzard]) -> WeatherBonus = 10 ; WeatherBonus = 0 )
    ; WeatherBonus = 0 ),
    inv(A, Inv),
    ( member(stack{tag: shadow_cloak, qty: _}, Inv) -> EquipBonus = 10 ; EquipBonus = 0 ),
    stat(A, dex, Dex), stat(A, luk, Luk),
    skill_val(A, stealth, Lvl),
    ( props(A, P), member(stealthy, P) -> RaceBonus = 10 ; RaceBonus = 0 ),
    random_between(1, 20, Roll),
    Score is Roll + Dex + floor(Lvl * 0.5) + floor(Luk * 0.2) + RaceBonus + LightBonus + WeatherBonus + EquipBonus,
    status:apply_aff(A, aff{type: hidden, val: Score, dur: 9999}, NA, _),
    skill_mod(NA, stealth, 1, FinalA),
    world:update(W, FinalA, NW),
    NLvl is Lvl + 1,
    Evts = [hidden(Id), skill_up(Id, stealth, NLvl)].

strip_stealth(A, NA) :-
    affs(A, Affs),
    ( select(aff{type: hidden, val: _, dur: _}, Affs, R) -> affs(A, R, NA) ; NA = A ).

step_disguise(W, Id, NW, [disguised(Id)]) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), member(stack{tag: disguise_mask, qty: _}, Inv),
    stat(A, cha, Cha), stat(A, dex, Dex),
    skill_val(A, stealth, Lvl),
    random_between(1, 20, Roll),
    Score is Roll + floor(Cha * 0.5) + floor(Dex * 0.3) + floor(Lvl * 0.5),
    status:apply_aff(A, aff{type: disguised, val: Score, dur: 9999}, NA, _),
    world:update(W, NA, NW).
