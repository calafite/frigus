:- module(survival, [
    tick_srv/5, step_rest/4, step_sleep/4, step_wake/4,
    step_drink/5, step_fill/4, step_fish/4
]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(env).

get_val(K, E, D, V) :- get_dict(K, E, V), !.
get_val(_, _, D, D).

tick_srv(W, Id, E, NE, Evts) :-
    get_val(hunger, E, 0, H),
    get_val(thirst, E, 0, T),
    get_val(fatigue, E, 0, F),
    get_val(state, E, normal, S),
    get_dict(env, W, Env),
    ( Env.weath == heatwave -> TMod = 4 ; TMod = 2 ),
    ( S == sleeping ->
        NH is min(100, H + 0.5), NT is min(100, T + 0.5), NF is max(0, F - 5),
        get_dict(max_hp, E, MHp), get_dict(max_mp, E, MMp),
        hp(E, Hp), mp(E, Mp),
        NHp is min(MHp, Hp + floor(MHp * 0.1)),
        NMp is min(MMp, Mp + floor(MMp * 0.1)),
        E1 = E.put(hp, NHp).put(mp, NMp),
        ( NF == 0 -> NS = normal, Evts1 = [woke_up(Id)] ; NS = sleeping, Evts1 = [] )
    ; S == resting ->
        NH is min(100, H + 1), NT is min(100, T + 1), NF is max(0, F - 2),
        get_dict(max_hp, E, MHp), get_dict(max_mp, E, MMp),
        hp(E, Hp), mp(E, Mp),
        NHp is min(MHp, Hp + floor(MHp * 0.05)),
        NMp is min(MMp, Mp + floor(MMp * 0.05)),
        E1 = E.put(hp, NHp).put(mp, NMp),
        NS = resting, Evts1 = []
    ;
        NH is min(100, H + 1), NT is min(100, T + TMod), NF is min(100, F + 1),
        E1 = E, NS = normal, Evts1 = []
    ),
    room(E1, RId), world:node(W, RId, N),
    ( member(deep_water, N.props), \+ (props(E1, P), member(swimming, P)), \+ (inv(E1, Inv), member(stack{tag: boat, qty: _}, Inv)) ->
        hp(E1, CurHp), NHp2 is max(0, CurHp - 20), E2 = E1.put(hp, NHp2), Evts2 = [drowning(Id) | Evts1]
    ; E2 = E1, Evts2 = Evts1 ),
    ( NH >= 100 ->
        hp(E2, CurHp2), NHp3 is max(0, CurHp2 - 5), E3 = E2.put(hp, NHp3), Evts3 = [starving(Id) | Evts2]
    ; E3 = E2, Evts3 = Evts2 ),
    ( NT >= 100 ->
        hp(E3, CurHp3), NHp4 is max(0, CurHp3 - 10), E4 = E3.put(hp, NHp4), Evts4 = [dehydrated(Id) | Evts3]
    ; E4 = E3, Evts4 = Evts3 ),
    NE = E4.put(hunger, NH).put(thirst, NT).put(fatigue, NF).put(state, NS),
    Evts = Evts4.

step_rest(W, Id, NW, [rest_start(Id)]) :-
    world:entity(W, Id, A), alive(A),
    world:update(W, A.put(state, resting), NW).

step_sleep(W, Id, NW, [sleep_start(Id)]) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    member(bed, N.props),
    world:update(W, A.put(state, sleeping), NW).

step_wake(W, Id, NW, [woke_up(Id)]) :-
    world:entity(W, Id, A), alive(A),
    world:update(W, A.put(state, normal), NW).

step_drink(W, Id, room, NW, [quenched(Id)]) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( member(river, N.props) ; member(lake, N.props) ; member(ocean, N.props) ),
    get_val(thirst, A, 0, T), NT is max(0, T - 50),
    world:update(W, A.put(thirst, NT), NW).

step_drink(W, Id, filled_waterskin, NW, [quenched(Id)]) :-
    world:entity(W, Id, A), alive(A),
    inv(A, Inv), inv_rem(Inv, filled_waterskin, 1, Tmp),
    inv_add(Tmp, empty_waterskin, 1, NInv),
    get_val(thirst, A, 0, T), NT is max(0, T - 50),
    world:update(W, A.put(inv, NInv).put(thirst, NT), NW).

step_fill(W, Id, NW, [filled_skin(Id)]) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( member(river, N.props) ; member(lake, N.props) ; member(ocean, N.props) ),
    inv(A, Inv), inv_rem(Inv, empty_waterskin, 1, Tmp),
    inv_add(Tmp, filled_waterskin, 1, NInv),
    world:update(W, A.put(inv, NInv), NW).

step_fish(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( member(river, N.props) ; member(lake, N.props) ; member(ocean, N.props) ),
    inv(A, Inv), member(stack{tag: fishing_pole, qty: _}, Inv),
    stat(A, dex, Dex), random_between(1, 20, Roll),
    ( Roll + Dex >= 15 ->
        inv_add(Inv, raw_fish, 1, NInv),
        Evts = [caught_fish(Id)],
        world:update(W, A.put(inv, NInv), NW)
    ;
        Evts = [fish_got_away(Id)],
        NW = W
    ).
