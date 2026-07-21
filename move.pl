:- module(move, [step_move/5, step_jump/5]).

:- use_module(world).
:- use_module(entity).
:- use_module(map).
:- use_module(visibility).

step_move(W, Id, Dir, NW, [moved(Id, Dir, NRId) | SideEvts]) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    visibility:resolve_exit(W, A, CurNode, Dir, NRId),
    world:node(W, NRId, NextNode),
    map:can_enter(W, A, CurNode, NextNode, Dir),
    map:on_exit(W, A, CurNode, MidA, ExitEvts),
    entity:room(MidA, NRId, MovedA),
    climb_state(MovedA, false, LandedA),
    map:on_enter(W, LandedA, NextNode, FinalA, EnterEvts),
    append(ExitEvts, EnterEvts, SideEvts),
    world:update(W, FinalA, NW).

step_jump(W, Id, Dir, NW, Evts) :-
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    get_dict(chasm_exits, CurNode, Chasms), member(Dir, Chasms),
    visibility:resolve_exit(W, A, CurNode, Dir, NRId),
    world:node(W, NRId, NextNode),
    stat(A, dex, Dex),
    random_between(1, 20, Roll),
    ( Roll + Dex >= 14 ->
        map:on_exit(W, A, CurNode, MidA, ExitEvts),
        entity:room(MidA, NRId, MovedA),
        map:on_enter(W, MovedA, NextNode, FinalA, EnterEvts),
        append(ExitEvts, EnterEvts, SideEvts),
        world:update(W, FinalA, NW),
        Evts = [jumped_gap(Id, Dir, NRId) | SideEvts]
    ;
        get_dict(chasm_fall_target, CurNode, FallId),
        world:node(W, FallId, FallNode),
        hp(A, Hp),
        NHp is max(0, Hp - 30),
        hp(A, NHp, HurtA),
        entity:room(HurtA, FallId, FellA),
        map:on_enter(W, FellA, FallNode, FinalA, EnterEvts),
        world:update(W, FinalA, NW),
        Evts = [failed_jump(Id, Dir, FallId), fallen(Id, 30) | EnterEvts]
    ).
