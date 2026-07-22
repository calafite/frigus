:- module(simulation, [tick_simulation/3]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(move).
:- use_module(nature).
:- use_module(economy).

tick_simulation(W, NW, Evts) :-
    spread_fire(W, W1, Evts1),
    apply_currents(W1, W2, Evts2),
    spread_diseases(W2, W3, Evts3),
    trigger_disasters(W3, W4, Evts4),
    tick_campfires(W4, W5, Evts5),
    tick_light_orbs(W5, W6, Evts6),
    nature:tick_crops(W6, W7, Evts7),
    economy:tick_economy(W7, NW, Evts8),
    append([Evts1, Evts2, Evts3, Evts4, Evts5, Evts6, Evts7, Evts8], Evts).

update_room(W, R, NW) :-
    select(O, W.rooms, Rest), O.id == R.id, !,
    NW = W.put(rooms, [R|Rest]).

flammable(R) :-
    get_dict(theme, R, Theme),
    member(Theme, [grove, forest, village, keep, swamp, ruins, mine]).

spread_fire(W, NW, Evts) :-
    findall(RId-I, (world:db_node(_, R), member(burning(I), R.props)), Burning),
    env:db_env(Env),
    do_fire(W, Burning, Env.weath, NW, Evts).

do_fire(W, [], _, W, []).
do_fire(W, [RId-I|T], Weath, NW, Evts) :-
    world:node(W, RId, R),
    ( (Weath == rain ; Weath == storm), R.type == outdoor ->
        NI is I - 1,
        ( NI =:= 0 ->
            select(burning(_), R.props, NProps),
            NR = R.put(props, NProps),
            Evt = [fire_extinguished(RId)]
        ;
            select(burning(_), R.props, Rest),
            NR = R.put(props, [burning(NI)|Rest]),
            Evt = [fire_dampened(RId, NI)]
        ),
        update_room(W, NR, W1),
        do_fire(W1, T, Weath, NW, REvts),
        append(Evt, REvts, Evts)
    ;
        NI is min(5, I + 1),
        select(burning(_), R.props, Rest),
        NR = R.put(props, [burning(NI)|Rest]),
        update_room(W, NR, W1),
        dict_keys(R.exits, Exits),
        spread_neighbors(W1, Exits, R.exits, RId, W2, SEvts),
        do_fire(W2, T, Weath, NW, REvts),
        append(SEvts, REvts, Evts)
    ).

spread_neighbors(W, [], _, _, W, []).
spread_neighbors(W, [Dir|Exits], ExitDict, RId, NW, Evts) :-
    get_dict(Dir, ExitDict, NId),
    world:node(W, NId, NR),
    flammable(NR),
    \+ member(burning(_), NR.props), !,
    NR1 = NR.put(props, [burning(1)|NR.props]),
    update_room(W, NR1, W1),
    spread_neighbors(W1, Exits, ExitDict, RId, NW, REvts),
    Evts = [fire_spread(RId, NId)|REvts].
spread_neighbors(W, [_|Exits], ExitDict, RId, NW, Evts) :-
    spread_neighbors(W, Exits, ExitDict, RId, NW, Evts).

apply_currents(W, NW, Evts) :-
    findall(E, (
        world:db_entity(_, _, E),
        alive(E), room(E, RId), world:node(W, RId, N),
        (member(current(Dir), N.props) ; member(flood_current(Dir), N.props))
    ), Ents),
    do_currents(W, Ents, NW, Evts).

do_currents(W, [], W, []).
do_currents(W, [E|T], NW, Evts) :-
    world:entity(W, E.id, CurE), alive(CurE),
    room(CurE, RId), world:node(W, RId, N),
    (member(current(Dir), N.props) -> true ; member(flood_current(Dir), N.props)),
    \+ (props(CurE, P), member(swimming, P)),
    \+ (inv(CurE, Inv), member(stack{tag: boat, qty: _}, Inv)),
    stat(CurE, str, Str), random_between(1, 20, Roll),
    Str + Roll < 18, !,
    ( get_dict(Dir, N.exits, NId) ->
        move:step_move(W, CurE.id, Dir, W1, MEvts),
        Evt = [swept_away(CurE.id, Dir, NId) | MEvts]
    ; W1 = W, Evt = [] ),
    do_currents(W1, T, NW, REvts),
    append(Evt, REvts, Evts).
do_currents(W, [_|T], NW, Evts) :- do_currents(W, T, NW, Evts).

spread_diseases(W, NW, Evts) :-
    findall(RId-Dis, (
        world:db_entity(_, _, E),
        alive(E), room(E, RId), affs(E, Affs),
        member(aff{type: Dis, val: _, dur: _}, Affs),
        member(Dis, [plague, fever, blight])
    ), Infected),
    sort(Infected, Unique),
    do_diseases(W, Unique, NW, Evts).

do_diseases(W, [], W, []).
do_diseases(W, [RId-Dis|T], NW, Evts) :-
    world:room_entities(W, RId, Ents),
    infect_room(W, Ents, Dis, W1, IEvts),
    do_diseases(W1, T, NW, REvts),
    append(IEvts, REvts, Evts).

infect_room(W, [], _, W, []).
infect_room(W, [E|T], Dis, NW, Evts) :-
    ( (is_dict(E, plyr) ; is_dict(E, mob)), alive(E), \+ (affs(E, Affs), member(aff{type: Dis, val: _, dur: _}, Affs)) ->
        disease_chance(Dis, Chance), random_between(1, 100, Roll),
        ( Roll <= Chance ->
            status:apply_aff(E, aff{type: Dis, val: 5, dur: 10}, NE, AEvts),
            world:update(W, NE, W1),
            Evt = [infected(E.id, Dis) | AEvts]
        ; W1 = W, Evt = [] )
    ; W1 = W, Evt = [] ),
    infect_room(W1, T, Dis, NW, REvts),
    append(Evt, REvts, Evts).

disease_chance(plague, 30).
disease_chance(fever, 20).
disease_chance(blight, 15).

trigger_disasters(W, NW, Evts) :-
    random_between(1, 100, Roll),
    ( Roll == 100 ->
        random_member(Disaster, [earthquake, flood, meteor, blizzard]),
        apply_disaster(Disaster, W, NW, Evts)
    ; NW = W, Evts = [] ).

apply_disaster(earthquake, W, NW, [disaster(earthquake) | Evts]) :-
    findall(R.id, (world:db_node(_, R), \+ member(safe, R.props)), NonSafe),
    apply_quake(W, NonSafe, NW, Evts).

apply_quake(W, [], W, []).
apply_quake(W, [RId|T], NW, Evts) :-
    world:node(W, RId, R),
    NR = R.put(props, [rubble|R.props]),
    update_room(W, NR, W1),
    world:room_entities(W1, RId, Ents),
    stun_entities(W1, Ents, W2, SEvts),
    apply_quake(W2, T, NW, REvts),
    append(SEvts, REvts, Evts).

stun_entities(W, [], W, []).
stun_entities(W, [E|T], NW, Evts) :-
    ( (is_dict(E, plyr) ; is_dict(E, mob)), alive(E) ->
        status:apply_aff(E, aff{type: stun, val: 0, dur: 2}, NE, AEvts),
        world:update(W, NE, W1),
        Evt = AEvts
    ; W1 = W, Evt = [] ),
    stun_entities(W1, T, NW, REvts),
    append(Evt, REvts, Evts).

apply_disaster(flood, W, NW, [disaster(flood)]) :-
    findall(R.id, (world:db_node(_, R), R.type == outdoor), Outdoor),
    apply_flood(W, Outdoor, NW).

apply_flood(W, [], W).
apply_flood(W, [RId|T], NW) :-
    world:node(W, RId, R),
    NR = R.put(props, [flooded, flood_current(east) | R.props]),
    update_room(W, NR, W1),
    apply_flood(W1, T, NW).

apply_disaster(meteor, W, NW, [disaster(meteor, RId) | Evts]) :-
    findall(R.id, (world:db_node(_, R), R.type == outdoor), Outdoor),
    random_member(RId, Outdoor),
    world:node(W, RId, R),
    ( member(burning(_), R.props) -> select(burning(_), R.props, RestProps) ; RestProps = R.props ),
    NR = R.put(props, [burning(4)|RestProps]),
    update_room(W, NR, W1),
    world:room_entities(W1, RId, Ents),
    scorch_entities(W1, Ents, W2, Evts),
    NW = W2.

scorch_entities(W, [], W, []).
scorch_entities(W, [E|T], NW, Evts) :-
    ( (is_dict(E, plyr) ; is_dict(E, mob)), alive(E) ->
        hp(E, Hp), NHp is max(0, Hp - 50),
        NE = E.put(hp, NHp),
        world:update(W, NE, W1),
        ( NHp =:= 0 -> Evt = [scorched(E.id, 50), dead(E.id)] ; Evt = [scorched(E.id, 50)] )
    ; W1 = W, Evt = [] ),
    scorch_entities(W1, T, NW, REvts),
    append(Evt, REvts, Evts).

apply_disaster(blizzard, W, NW, [disaster(blizzard) | Evts]) :-
    env:db_env(Env),
    ( Env.seas == winter ->
        NEnv = Env.put(weath, blizzard),
        retractall(env:db_env(_)), assertz(env:db_env(NEnv)),
        findall(E, (
            world:db_entity(_, _, E),
            alive(E), room(E, RId), world:node(W, RId, N), N.type == outdoor
        ), Ents),
        freeze_entities(W, Ents, NW, Evts)
    ; NW = W, Evts = [] ).

freeze_entities(W, [], W, []).
freeze_entities(W, [E|T], NW, Evts) :-
    status:apply_aff(E, aff{type: freeze, val: 0, dur: 3}, E1, AEvts),
    hp(E1, Hp), NHp is max(0, Hp - 10),
    NE = E1.put(hp, NHp),
    world:update(W, NE, W1),
    ( NHp =:= 0 -> Evt = [frostbite(E.id, 10), dead(E.id) | AEvts] ; Evt = [frostbite(E.id, 10) | AEvts] ),
    freeze_entities(W1, T, NW, REvts),
    append(Evt, REvts, Evts).

tick_campfires(W, NW, Evts) :-
    findall(RId-T, (world:db_node(_, R), member(campfire(T), R.props)), Camps),
    do_campfires(W, Camps, NW, Evts).

do_campfires(W, [], W, []).
do_campfires(W, [RId-T|Ts], NW, Evts) :-
    world:node(W, RId, R),
    NT is T - 1,
    ( NT =:= 0 ->
        select(campfire(_), R.props, NProps),
        ( member(originally_dark, R.props) ->
            select(originally_dark, NProps, Rest),
            NRProps = [dark|Rest]
        ; NRProps = NProps ),
        NR = R.put(props, NRProps),
        Evt = [campfire_out(RId)]
    ;
        select(campfire(_), R.props, Rest),
        NR = R.put(props, [campfire(NT)|Rest]),
        Evt = []
    ),
    update_room(W, NR, W1),
    do_campfires(W1, Ts, NW, REvts),
    append(Evt, REvts, Evts).

tick_light_orbs(W, NW, Evts) :-
    findall(RId-T, (world:db_node(_, R), member(light_orb(T), R.props)), Orbs),
    do_light_orbs(W, Orbs, NW, Evts).

do_light_orbs(W, [], W, []).
do_light_orbs(W, [RId-T|Ts], NW, Evts) :-
    world:node(W, RId, R),
    NT is T - 1,
    ( NT =:= 0 ->
        select(light_orb(_), R.props, NProps),
        ( member(originally_dark, R.props) ->
            select(originally_dark, NProps, Rest),
            NRProps = [dark|Rest]
        ; NRProps = NProps ),
        NR = R.put(props, NRProps),
        Evt = [light_orb_dissipated(RId)]
    ;
        select(light_orb(_), R.props, Rest),
        NR = R.put(props, [light_orb(NT)|Rest]),
        Evt = []
    ),
    update_room(W, NR, W1),
    do_light_orbs(W1, Ts, NW, REvts),
    append(Evt, REvts, Evts).
