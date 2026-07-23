:- module(move, [step_move/5, step_jump/5, step_travel/5, resolve_dir/2]).

:- use_module(world).
:- use_module(entity).
:- use_module(map).
:- use_module(visibility).
:- use_module(cfg_zone).
:- use_module(chunks).
:- use_module(library(random)).
:- use_module(library(lists)).

resolve_dir(n, north) :- !.
resolve_dir(s, south) :- !.
resolve_dir(e, east) :- !.
resolve_dir(w, west) :- !.
resolve_dir(u, up) :- !.
resolve_dir(d, down) :- !.
resolve_dir(Query, Dir) :-
    atom_string(Atom, Query),
    resolve_dir(Atom, Dir), !.
resolve_dir(Dir, Dir).

step_move(W, Id, DirQuery, NW, Evts) :-
    resolve_dir(DirQuery, Dir),
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    ( visibility:resolve_exit(W, A, CurNode, Dir, NRId) ->
        chunks:ensure_chunk(W, NRId, W1),
        world:node(W1, NRId, NextNode),
        ( map:can_enter(W1, A, CurNode, NextNode, Dir) ->
            map:on_exit(W1, A, CurNode, MidA, ExitEvts),
            ( get_dict(terrain, NextNode, Terrain) -> true ; Terrain = stone ),
            ( cfg_zone:terrain_fatigue(Terrain, BaseFCost) -> true ; BaseFCost = 1 ),
            ( is_encumbered(MidA) -> FCost is BaseFCost * 2 ; FCost = BaseFCost ),
            ( get_dict(fatigue, MidA, F) -> true ; F = 0 ),
            NF is min(100, F + FCost),
            entity:room(MidA.put(fatigue, NF), NRId, MovedA),
            climb_state(MovedA, false, LandedA),
            map:on_enter(W1, LandedA, NextNode, FinalA, EnterEvts),
            append(ExitEvts, EnterEvts, SideEvts),
            world:update(W1, FinalA, NW),
            Evts = [moved(Id, Dir, NRId) | SideEvts]
        ;
            NW = W, Evts = [cannot_enter(Id, Dir, NRId)]
        )
    ;
        NW = W, Evts = [no_exit(Id, DirQuery)]
    ).

step_jump(W, Id, DirQuery, NW, Evts) :-
    resolve_dir(DirQuery, Dir),
    world:entity(W, Id, A),
    entity:room(A, RId),
    world:node(W, RId, CurNode),
    ( get_dict(chasm_exits, CurNode, Chasms), member(Dir, Chasms), visibility:resolve_exit(W, A, CurNode, Dir, NRId) ->
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
            ( get_dict(chasm_fall_target, CurNode, FallId) -> true ; FallId = RId ),
            chunks:ensure_chunk(W1, FallId, W2),
            world:node(W2, FallId, FallNode),
            hp(A, Hp),
            NHp is max(0, Hp - 30),
            hp(A, NHp, HurtA),
            entity:room(HurtA, FallId, FellA),
            map:on_enter(W2, FellA, FallNode, FinalA, EnterEvts),
            world:update(W2, FinalA, NW),
            Evts = [failed_jump(Id, Dir, FallId), fallen(Id, 30) | EnterEvts]
        )
    ;
        NW = W, Evts = [no_chasm(Id, DirQuery)]
    ).

step_travel(W, Id, DestId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), \+ altitude(A, air),
    room(A, CurId), world:node(W, CurId, CurNode),
    ( member(safe, CurNode.props),
      chunks:ensure_chunk(W, DestId, W1),
      world:node(W1, DestId, DestNode),
      member(safe, DestNode.props),
      member(landmark, DestNode.props),
      get_dict(landmarks, A, Known), member(DestId, Known),
      ( get_dict(region, CurNode, R1) -> true ; R1 = wilderness ),
      ( get_dict(region, DestNode, R2) -> true ; R2 = wilderness ),
      ( cfg_zone:region_of(R1, Reg1) -> true ; Reg1 = R1 ),
      ( cfg_zone:region_of(R2, Reg2) -> true ; Reg2 = R2 ),
      ( Reg1 == Reg2 -> Cost = 50, Fat = 20 ; Cost = 150, Fat = 50 ),
      inv(A, Inv), inv_rem(Inv, gold, Cost, NInv)
    ->
        get_dict(fatigue, A, F), NF is min(100, F + Fat),
        A1 = A.put(inv, NInv).put(fatigue, NF).put(room, DestId),
        world:update(W1, A1, NW),
        Evts = [fast_traveled(Id, DestId)]
    ;
        NW = W, Evts = [cannot_travel(Id, DestId)]
    ).
