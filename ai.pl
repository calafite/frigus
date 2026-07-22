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
:- use_module(npc_life).
:- use_module(social).
:- use_module(ai_path).
:- use_module(ai_pet).
:- use_module(ai_dragon).

step_ai(W, Id, NW, Evts) :- world:entity(W, Id, M), \+ status:can_act(M), NW = W, Evts = [], !.
step_ai(W, Id, NW, Evts) :- world:entity(W, Id, M), props(M, P), member(surrendered, P), NW = W, Evts = [], !.
step_ai(W, Id, NW, Evts) :- world:entity(W, Id, M), get_dict(tag, M, dragon), ai_dragon:ai_dragon_act(W, Id, NW, Evts), Evts \== [], !.
step_ai(W, Id, NW, Evts) :- world:entity(W, Id, M), get_dict(master, M, _), ai_pet:ai_pet_act(W, Id, NW, Evts), Evts \== [], !.
step_ai(W, Id, NW, Evts) :- ai_arrest(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_surrender(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_flee(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_call_help(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_respond_help(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_murder(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_rob(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_mania(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_role(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_attack(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- ai_group_up(W, Id, NW, Evts), !.
step_ai(W, Id, NW, Evts) :- npc_life:step_life(W, Id, NW, Evts), Evts \== [], !.
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
hates(M, T) :- is_dict(T, plyr), npc_life:get_mem(M, T.id, Val), Val =< -20, !.

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

ai_arrest(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:role(M.tag, protector),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), is_dict(T, plyr),
    can_spot_criminal(W, M, T, W1, BlowEvts), !,
    fac(T, citizen, T1),
    ( find_prison(W1, PrisonId) -> true ; PrisonId = RId ),
    bounty(T, B),
    JTime is min(120, max(10, floor(B / 5))),
    T2 = T1.put(room, PrisonId).put(hp, 1).put(jail_time, JTime),
    inv(T2, Inv), inv_rem_all(Inv, gold, NInv), T3 = T2.put(inv, NInv),
    world:update(W1, T3, NW),
    append(BlowEvts, [arrested(Id, T.id, PrisonId, JTime)], Evts).

can_spot_criminal(W, Guard, T, NW, BlowEvts) :-
    fac(T, criminal),
    ( affs(T, Affs), member(aff{type: disguised, val: Score, dur: _}, Affs) ->
        stat(Guard, wis, Wis),
        random_between(1, 20, Roll),
        ( Roll + Wis >= Score ->
            select(aff{type: disguised, val: _, dur: _}, Affs, Rest),
            T1 = T.put(affs, Rest),
            world:update(W, T1, NW),
            BlowEvts = [disguise_blown(Guard.id, T.id)]
        ;
            NW = W, BlowEvts = [], fail
        )
    ;
        NW = W, BlowEvts = []
    ).

inv_rem_all(Inv, Tag, NInv) :-
    ( select(stack{tag: Tag, qty: _}, Inv, Rest) -> NInv = Rest ; NInv = Inv ).

find_prison(W, PrisonId) :-
    findall(R.id, (member(R, W.rooms), member(prison, R.props)), Cands),
    random_member(PrisonId, Cands).

ai_surrender(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    hp(M, Hp), get_dict(max_hp, M, MaxHp),
    cfg_ai:courage(M.tag, C),
    Hp =< MaxHp * C, Hp =< MaxHp * 0.15,
    room(M, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits == [],
    \+ (props(M, P), member(surrendered, P)), !,
    props(M, P), M1 = M.put(props, [surrendered|P]),
    world:update(W, M1, NW),
    Evts = [surrendered(Id)].

ai_flee(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    hp(M, Hp), get_dict(max_hp, M, MaxHp),
    cfg_ai:courage(M.tag, C), Hp < MaxHp * C,
    room(M, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [], random_member(Dir, Exits),
    move:step_move(W, Id, Dir, NW, Evts).

ai_flee(W, Id, NW, Evts) :-
    world:entity(W, Id, M), \+ is_combatant(M),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(T, M), is_combatant(T), !,
    world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [], random_member(Dir, Exits),
    move:step_move(W, Id, Dir, NW, Evts).

ai_call_help(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:vocal(M.tag),
    hp(M, Hp), get_dict(max_hp, M, MaxHp), Hp =< MaxHp * 0.5,
    \+ get_dict(called_help, M, true),
    room(M, RId), world:flags(W, Fs),
    NFs = Fs.put(help_call_room, RId).put(help_call_tag, M.tag),
    world:flags(W, NFs, W1),
    world:update(W1, M.put(called_help, true), NW),
    Evts = [called_for_help(Id, RId)].

ai_respond_help(W, Id, NW, Evts) :-
    world:entity(W, Id, M), world:flags(W, Fs),
    get_dict(help_call_room, Fs, CallRId),
    get_dict(help_call_tag, Fs, CallTag),
    M.tag == CallTag, room(M, RId), RId \== CallRId,
    ai_path:step_towards(W, Id, CallRId, NW, Evts),
    Evts \== [], !.

ai_murder(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:mania(M.tag, murderer),
    random_between(1, 100, R), R =< 25,
    affs(M, Affs), member(aff{type: hidden, val: _, dur: _}, Affs),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(M, T), combat:valid_target(W, M, T), !,
    combat:step_kill(W, Id, T.id, NW, Evts).

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
    member(T, Ents), alive(T), Id \== T.id,
    (T.tag == M.tag ; is_humanoid(T)),
    combat:valid_target(W, M, T),
    hp(T, Hp), get_dict(max_hp, T, Max), Hp =< Max * 0.3, !,
    combat:step_kill(W, Id, T.id, NW, Evts).

ai_mania_act(hoarder, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(I, Ents), is_dict(I, item), !,
    item:step_loot(W, Id, I.id, NW, Evts).

ai_mania_act(kleptomaniac, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), Id \== T.id,
    inv(T, Inv), Inv \= [], random_member(Stack, Inv), Stack.tag \== gold, !,
    npc:step_steal(W, Id, T.id, Stack.tag, 1, NW, Evts).

ai_mania_act(martyr, W, Id, M, NW, Evts) :-
    hp(M, Hp), get_dict(max_hp, M, Max), Hp =< Max * 0.2,
    room(M, RId), world:room_entities(W, RId, Ents),
    findall(T, (member(T, Ents), alive(T), T.id \== Id, hates(M, T)), Tgts),
    Tgts \= [], !,
    combat:step_cast(W, Id, holy_light, M.id, NW, CEvts),
    Evts = [martyr_explosion(Id) | CEvts].

ai_mania_act(sadist, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), Id \== T.id, hates(M, T),
    combat:valid_target(W, M, T),
    \+ (affs(T, Affs), member(aff{type: bloodline_curse, dur: _, val: _}, Affs)),
    random_between(1, 100, R), R =< 20, !,
    status:apply_aff(T, aff{type: bloodline_curse, val: 8, dur: 6}, T1, AEvts),
    world:update(W, T1, NW),
    Evts = [sadistic_torture(Id, T.id) | AEvts].

ai_mania_act(pyromaniac, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), Id \== T.id,
    random_between(1, 100, R), R =< 10, !,
    combat:step_cast(W, Id, fireball, T.id, NW, Evts).

ai_role(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    cfg_ai:role(M.tag, Role),
    ai_role_act(Role, W, Id, M, NW, Evts).

ai_role_act(protector, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), hates(M, T), combat:valid_target(W, M, T), !,
    combat:step_kill(W, Id, T.id, NW, Evts).

ai_role_act(healer, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), alive(T), Id \== T.id, \+ hates(M, T),
    hp(T, Hp), get_dict(max_hp, T, Max), Hp < Max * 0.5, !,
    combat:step_cast(W, Id, mend, T.id, NW, Evts).

ai_role_act(worker, W, Id, M, NW, Evts) :-
    room(M, RId), world:room_entities(W, RId, Ents),
    member(I, Ents), is_dict(I, item), I.tag == timber, !,
    item:step_loot(W, Id, I.id, NW, Evts).

ai_attack(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    room(M, RId), world:room_entities(W, RId, Ents),
    combat:get_highest_threat(M, BestId),
    ( BestId \== none, member(T, Ents), T.id == BestId ->
        Tgt = T
    ;
        member(T, Ents), alive(T), should_attack(M, T), combat:valid_target(W, M, T) -> Tgt = T
    ), !,
    combat:step_kill(W, Id, Tgt.id, NW, Evts).

ai_group_up(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:herd(M.tag),
    \+ get_dict(party, M, _),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), (is_dict(T, mob) ; is_dict(T, plyr)), T.id \== Id, T.tag == M.tag,
    get_dict(party, T, PId), PId \== none, !,
    social:step_party(W, Id, join(PId), NW, Evts).

ai_group_up(W, Id, NW, Evts) :-
    world:entity(W, Id, M), cfg_ai:herd(M.tag),
    \+ get_dict(party, M, _),
    room(M, RId), world:room_entities(W, RId, Ents),
    member(T, Ents), (is_dict(T, mob) ; is_dict(T, plyr)), T.id \== Id, T.tag == M.tag,
    \+ get_dict(party, T, _), !,
    social:step_party(W, Id, create, W1, [party_created(Id, PId)]),
    social:step_party(W1, T.id, join(PId), NW, Evts2),
    Evts = [formed_herd(Id, T.id, PId) | Evts2].

ai_hide(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(tag, M, shadow_panther),
    \+ (affs(M, Affs), member(aff{type: hidden, val: _, dur: _}, Affs)), !,
    stealth:step_hide(W, Id, NW, Evts).

ai_chase(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    combat:get_highest_threat(M, BestId),
    ( BestId \== none -> TgtId = BestId
    ; should_attack(M, T), TgtId = T.id ), !,
    ai_path:step_towards(W, Id, TgtId, NW, Evts).

ai_patrol(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(route, M, Route), get_dict(route_idx, M, Idx),
    length(Route, Len), NIdx is (Idx + 1) mod Len, nth0(NIdx, Route, NRId),
    room(M, RId), world:node(W, RId, N), get_dict(Dir, N.exits, NRId),
    NM = M.put(route_idx, NIdx), world:update(W, NM, TW),
    move:step_move(TW, Id, Dir, NW, Evts).

ai_wander(W, Id, NW, Evts) :-
    world:entity(W, Id, M), get_dict(wander, M, true),
    room(M, RId), world:node(W, RId, N), dict_keys(N.exits, Exits), Exits \= [],
    random_member(Dir, Exits),
    move:step_move(W, Id, Dir, NW, Evts).
