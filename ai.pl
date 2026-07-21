:- module(ai, [step_ai/4]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(config).
:- use_module(cfg_ai).
:- use_module(entity).
:- use_module(world).
:- use_module(move).
:- use_module(combat).
:- use_module(npc).
:- use_module(status).
:- use_module(stealth).
:- use_module(magic).
:- use_module(item).

step_ai(W, Id, NW, Evts) :- world:entity(W, Id, M), \+ status:can_act(M), NW = W, Evts = [], !.
step_ai(W, Id, NW, Evts) :- ai_flee(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_murder(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_rob(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_mania(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_role(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_attack(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_hide(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_chase(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_patrol(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_wander(W, Id, NW, Evts), !.
step_ai(W, _, W, []).

id_grp(E, G) :- get_dict(tag, E, G).
id_grp(E, G) :- get_dict(race, E, G).
id_grp(E, G) :- get_dict(class, E, G).
id_grp(E, G) :- get_dict(fac, E, G).
id_grp(E, G) :- get_dict(props, E, P), member(G, P).
id_grp(E, monster) :- is_dict(E, mob), get_dict(tag, E, Tag), config:aggression(Tag, aggressive).

hates(M, T) :- id_grp(M, G1), id_grp(T, G2), cfg_ai:hate(G1, G2), !.

is_combatant(E) :- cfg_ai:role(E.tag, protector), !.
is_combatant(E) :- id_grp(E, monster), !.
is_combatant(E) :- id_grp(E, bandit), !.
is_combatant(E) :- id_grp(E, cultist), !.
is_combatant(E) :- id_grp(E, murderer), !.
is_combatant(E) :- id_grp(E, boss), !.
is_combatant(E) :- id_grp(E, elite), !.

should_attack(M, T) :- is_combatant(M), hates(M, T), !.
should_attack(M, T) :- get_dict(tag, M, Tag), config:aggression(Tag, aggressive), combat:dynamic_enemy(M, T), !.
should_attack(M, T) :-
    get_dict(tag, M, Tag), config:aggression(Tag, neutral),
    hp(M, Hp), get_dict(max_hp, M, Max), Hp < Max, combat:dynamic_enemy(M, T).

has_blood(T) :- \+ member(T.tag, [skeleton, golem, iron_golem, elemental, fire_sprite, slime, ghost, wraith]).
is_humanoid(T) :- id_grp(T, human) ; id_grp(T, elf) ; id_grp(T, dwarf) ; id_grp(T, orc) ; id_grp(T, goblin).

ai_flee(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    hp(M, Hp), get_dict(max_hp, M, MaxHp), Hp < MaxHp * 0.2,
    room(M, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [], random_member(Dir, Exits),
    step_move(W, Id, Dir, NW, Evts).

ai_flee(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    \+ is_combatant(M),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(T, M), is_combatant(T), !,
    world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [], random_member(Dir, Exits),
    step_move(W, Id, Dir, NW, Evts).

ai_murder(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:mania(M.tag, murderer),
    random_between(1, 100, R), R =< 25,
    affs(M, Affs), member(aff{type: hidden, val: _, dur: _}, Affs),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(M, T), combat:valid_target(W, M, T), !,
    stealth:strip_stealth(M, CleanM),
    combat:calc_dmg(CleanM, CleanM.tag, Base), Dmg is Base * 6,
    combat:apply_dmg(W, CleanM, T, Dmg, none, NW, CEvts, assassinate(Id, T.id, Dmg)),
    Evts = CEvts.

ai_murder(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:mania(M.tag, murderer),
    random_between(1, 100, R), R =< 25,
    \+ (affs(M, Affs), member(aff{type: hidden, val: _, dur: _}, Affs)),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(M, T), !,
    stealth:step_hide(W, Id, NW, Evts).

ai_rob(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:mania(M.tag, mugger),
    random_between(1, 100, R), R =< 15,
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id,
    inv(T, Inv), member(stack{tag: gold, qty: Q}, Inv), Q > 0, !,
    StlQ is min(Q, 50),
    npc:step_steal(W, Id, T.id, gold, StlQ, NW, Evts).

ai_mania(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    cfg_ai:mania(M.tag, Mania),
    random_between(1, 100, R), R =< 15, !,
    ai_mania_act(Mania, W, Id, M, NW, Evts).

ai_mania_act(sanguivore, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id, has_blood(T),
    combat:valid_target(W, M, T),
    hp(T, Hp), get_dict(max_hp, T, Max), Hp =< Max * 0.5, !,
    NHp is max(0, Hp - 15), hp(T, NHp, T1),
    hp(M, MHp), get_dict(max_hp, M, MMax), NMHp is min(MMax, MHp + 15), hp(M, NMHp, M1),
    world:update(W, M1, W1), world:update(W1, T1, NW),
    ( NHp =:= 0 -> Evts = [drink_blood(Id, T.id, 15), dead(T.id)] ; Evts = [drink_blood(Id, T.id, 15)] ).

ai_mania_act(cannibal, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id,
    (T.tag == M.tag ; is_humanoid(T)),
    combat:valid_target(W, M, T),
    hp(T, Hp), get_dict(max_hp, T, Max), Hp =< Max * 0.3, !,
    combat:apply_dmg(W, M, T, 35, none, NW, DEvts, eat_flesh(Id, T.id, 35)),
    Evts = DEvts.

ai_mania_act(hoarder, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(I, Ents), is_dict(I, item), !,
    item:step_loot(W, Id, I.id, NW, Evts).

ai_mania_act(kleptomaniac, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id,
    inv(T, Inv), Inv \= [], random_member(Stack, Inv), Stack.tag \== gold, !,
    npc:step_steal(W, Id, T.id, Stack.tag, 1, NW, Evts).

ai_mania_act(martyr, W, Id, M, NW, Evts) :-
    hp(M, Hp), get_dict(max_hp, M, Max), Hp =< Max * 0.2,
    room(M, RId), world:room_entities(W, RId, Ents),
    findall(T, (member(T, Ents), alive(T), T.id \== Id, hates(M, T)), Tgts),
    Tgts \= [], !,
    magic:apply_cataclysm(W, M, holy_light, Tgts, none, W1, CEvts),
    hp(M, 0, M1), world:update(W1, M1, NW),
    Evts = [martyr_explosion(Id) | CEvts].

ai_mania_act(sadist, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id, hates(M, T),
    combat:valid_target(W, M, T),
    \+ (affs(T, Affs), member(aff{type: bloodline_curse, dur: _, val: _}, Affs)),
    random_between(1, 100, R), R =< 20, !,
    status:apply_aff(T, aff{type: bloodline_curse, val: 8, dur: 6}, T1, AEvts),
    world:update(W, T1, NW),
    Evts = [sadistic_torture(Id, T.id) | AEvts].

ai_mania_act(pyromaniac, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id,
    random_between(1, 100, R), R =< 10, !,
    magic:step_cast(W, Id, fireball, T.id, NW, Evts).

ai_role(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    cfg_ai:role(M.tag, Role),
    ai_role_act(Role, W, Id, M, NW, Evts).

ai_role_act(protector, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(M, T), combat:valid_target(W, M, T), !,
    step_kill(W, Id, T.id, NW, Evts).

ai_role_act(healer, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), M.id \== T.id, \+ hates(M, T),
    hp(T, Hp), get_dict(max_hp, T, Max), Hp < Max * 0.5, !,
    magic:step_cast(W, Id, heal, T.id, NW, Evts).

ai_role_act(worker, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(I, Ents), is_dict(I, item), I.tag == timber, !,
    item:step_loot(W, Id, I.id, NW, Evts).

ai_attack(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), should_attack(M, T), combat:valid_target(W, M, T), !,
    step_kill(W, Id, T.id, NW, Evts).

ai_hide(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(tag, M, shadow_panther),
    \+ (affs(M, Affs), member(aff{type: hidden, val: _, dur: _}, Affs)), !,
    stealth:step_hide(W, Id, NW, Evts).

ai_chase(W, Id, NW, Evts) :-
    world:entity(W, Id, M), should_attack(M, T),
    room(M, RId), world:node(W, RId, N), get_dict(Dir, N.exits, NRId),
    world:room_entities(W, NRId, Ents), member(T, Ents), alive(T),
    combat:dynamic_enemy(M, T), !,
    step_move(W, Id, Dir, NW, Evts).

ai_patrol(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(route, M, Route), get_dict(route_idx, M, Idx),
    length(Route, Len), NIdx is (Idx + 1) mod Len, nth0(NIdx, Route, NRId),
    room(M, RId), world:node(W, RId, N), get_dict(Dir, N.exits, NRId),
    NM = M.put(route_idx, NIdx), world:update(W, NM, TW),
    step_move(TW, Id, Dir, NW, Evts).

ai_wander(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(wander, M, true),
    room(M, RId), world:node(W, RId, N), dict_keys(N.exits, Exits), Exits \= [],
    random_member(Dir, Exits),
    step_move(W, Id, Dir, NW, Evts).
