:- module(move, [step_move/5, step_jump/5, step_travel/5]).

:- use_module(world).
:- use_module(entity).
:- use_module(map).
:- use_module(visibility).
:- use_module(cfg_zone).
:- use_module(chunks).

step_move(W, Id, Dir, NW, [moved(Id, Dir, NRId) | SideEvts]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    visibility:resolve_exit(W, A, CurNode, Dir, NRId),
    chunks:ensure_chunk(W, NRId, W1),
    world:node(W1, NRId, NextNode),
    map:can_enter(W1, A, CurNode, NextNode, Dir),
    map:on_exit(W1, A, CurNode, MidA, ExitEvts),
    get_dict(terrain, NextNode, Terrain),
    cfg_zone:terrain_fatigue(Terrain, BaseFCost),
    ( is_encumbered(MidA) -> FCost is BaseFCost * 2 ; FCost = BaseFCost ),
    get_dict(fatigue, MidA, F),
    NF is min(100, F + FCost),
    entity:room(MidA.put(fatigue, NF), NRId, MovedA),
    climb_state(MovedA, false, LandedA),
    map:on_enter(W1, LandedA, NextNode, FinalA, EnterEvts),
    append(ExitEvts, EnterEvts, SideEvts),
    world:update(W1, FinalA, NW).

step_jump(W, Id, Dir, NW, Evts) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    get_dict(chasm_exits, CurNode, Chasms), member(Dir, Chasms),
    visibility:resolve_exit(W, A, CurNode, Dir, NRId),
    chunks:ensure_chunk(W, NRId, W1),
    world:node(W1, NRId, NextNode),
    stat(A, dex, Dex), stat(A, luk, Luk),
    random_between(1, 20, Roll),
    ( Roll + Dex + floor(Luk * 0.2) >= 14 ->
        map:on_exit(W1, A, CurNode, MidA, ExitEvts),
        entity:room(MidA, NRId, MovedA),
        map:on_enter(W1, MovedA, NextNode, FinalA, EnterEvts),
        append(ExitEvts, EnterEvts, SideEvts),
        world:update(W1, FinalA, NW),
        Evts = [jumped_gap(Id, Dir, NRId) | SideEvts]
    ;
        get_dict(chasm_fall_target, CurNode, FallId),
        chunks:ensure_chunk(W1, FallId, W2),
        world:node(W2, FallId, FallNode),
        hp(A, Hp),
        NHp is max(0, Hp - 30),
        hp(A, NHp, HurtA),
        entity:room(HurtA, FallId, FellA),
        map:on_enter(W2, FellA, FallNode, FinalA, EnterEvts),
        world:update(W2, FinalA, NW),
        Evts = [failed_jump(Id, Dir, FallId), fallen(Id, 30) | EnterEvts]
    ).

step_travel(W, Id, DestId, NW, [fast_traveled(Id, DestId)]) :-
    world:entity(W, Id, A), alive(A), \+ altitude(A, air),
    room(A, CurId), world:node(W, CurId, CurNode),
    member(safe, CurNode.props),
    chunks:ensure_chunk(W, DestId, W1),
    world:node(W1, DestId, DestNode),
    member(safe, DestNode.props),
    member(landmark, DestNode.props),
    get_dict(landmarks, A, Known), member(DestId, Known),
    cfg_zone:region_of(CurNode.region, R1),
    cfg_zone:region_of(DestNode.region, R2),
    ( R1 == R2 -> Cost = 50, Fat = 20 ; Cost = 150, Fat = 50 ),
    inv(A, Inv), inv_rem(Inv, gold, Cost, NInv),
    get_dict(fatigue, A, F), NF is min(100, F + Fat),
    A1 = A.put(inv, NInv).put(fatigue, NF).put(room, DestId),
    world:update(W1, A1, NW).
