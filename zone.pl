:- module(zone, [
    step_break/5, step_lock/5, step_unlock/5,
    step_buy/4, step_furn/6, step_pick/5, update_room/3
]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(cfg_zone).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).
:- use_module(move).

update_room(W, R, NW) :- world:update(W, R, NW).

id_gen(Prefix, Id) :- random_between(1000000, 9999999, R), atomic_list_concat([Prefix, '_', R], Id).

step_break(W, Id, ObjId, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( get_dict(breakables, N, B), get_dict(ObjId, B, Obj) ->
        wpn(A, Wpn),
        ( config:dmg(Wpn, BaseDmg) -> true ; BaseDmg = 1 ),
        stat(A, str, Str), stat(A, con, Con),
        Dmg is BaseDmg + floor(Str * 0.5) + floor(Con * 0.2),
        NHp is Obj.hp - Dmg,
        ( NHp =< 0 ->
            del_dict(ObjId, B, _, NB),
            cfg_zone:breakable_data(Obj.type, Drops, Xp),
            prog:add_xp(A, Xp, NA, XpEvts),
            world:update(W, NA, W1),
            spawn_drops(W1, RId, Drops, W2, DropEvts),
            NN = N.put(breakables, NB),
            update_room(W2, NN, NW),
            append([broken_obj(ObjId), damage_obj(ObjId, Dmg) | XpEvts], DropEvts, Evts)
        ;
            NObj = Obj.put(hp, NHp), NB = B.put(ObjId, NObj),
            NN = N.put(breakables, NB), update_room(W, NN, NW),
            Evts = [damage_obj(ObjId, Dmg)]
        )
    ;
        NW = W, Evts = [nothing_to_break(Id, ObjId)]
    ).

spawn_drops(W, _, [], W, []).
spawn_drops(W, RId, [stack{tag: T, qty: Q}|Ts], NW, [dropped(IId, T, Q)|Evts]) :-
    id_gen(drop, IId),
    Item = item{id: IId, tag: T, qty: Q, room: RId},
    world:add(W, item, Item, W1),
    spawn_drops(W1, RId, Ts, NW, Evts).

step_lock(W, Id, DirQuery, NW, Evts) :-
    move:resolve_dir(DirQuery, Dir),
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( get_dict(locks, N, Locks), get_dict(Dir, Locks, Key),
      ( get_dict(owner, N, Owner) -> (Owner == Id ; member(Id, N.officers) ; Owner == none) ; true ),
      get_dict(locked_exits, N, Ls), \+ member(Dir, Ls),
      inv(A, Inv), member(stack{tag: Key, qty: _}, Inv)
    ->
        NN = N.put(locked_exits, [Dir|Ls]), update_room(W, NN, NW),
        Evts = [locked_exit(Id, Dir)]
    ;
        NW = W, Evts = [cannot_lock(Id, DirQuery)]
    ).

step_unlock(W, Id, DirQuery, NW, Evts) :-
    move:resolve_dir(DirQuery, Dir),
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( get_dict(locks, N, Locks), get_dict(Dir, Locks, Key),
      get_dict(locked_exits, N, Ls), member(Dir, Ls),
      inv(A, Inv), member(stack{tag: Key, qty: _}, Inv)
    ->
        select(Dir, Ls, NLs), NN = N.put(locked_exits, NLs),
        update_room(W, NN, NW),
        Evts = [unlocked_exit(Id, Dir)]
    ;
        NW = W, Evts = [cannot_unlock(Id, DirQuery)]
    ).

step_buy(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( member(for_sale(Cost), N.props), inv(A, Inv), inv_rem(Inv, gold, Cost, NInv) ->
        select(for_sale(_), N.props, NProps),
        NN = N.put(props, NProps).put(owner, Id),
        world:update(W, A.put(inv, NInv), W1),
        update_room(W1, NN, NW),
        Evts = [property_bought(Id, RId)]
    ;
        NW = W, Evts = [cannot_buy_property(Id, RId)]
    ).

step_furn(W, Id, FurnId, sit, NW, Evts) :-
    world:entity(W, Id, A), alive(A), room(A, RId), world:node(W, RId, N),
    ( get_dict(furniture, N, F), get_dict(FurnId, F, Furn),
      Furn.type == chair, Furn.user == none
    ->
        NFurn = Furn.put(user, Id), NF = F.put(FurnId, NFurn), NN = N.put(furniture, NF),
        world:update(W, A.put(state, resting), W1), update_room(W1, NN, NW),
        Evts = [sat_down(Id, FurnId)]
    ;
        NW = W, Evts = [cannot_sit(Id, FurnId)]
    ).

step_furn(W, Id, FurnId, stand, NW, Evts) :-
    world:entity(W, Id, A), alive(A), room(A, RId), world:node(W, RId, N),
    ( get_dict(furniture, N, F), get_dict(FurnId, F, Furn),
      Furn.user == Id
    ->
        NFurn = Furn.put(user, none), NF = F.put(FurnId, NFurn),
        NN = N.put(furniture, NF), world:update(W, A.put(state, normal), W1),
        update_room(W1, NN, NW),
        Evts = [stood_up(Id, FurnId)]
    ;
        NW = W, Evts = [cannot_stand(Id, FurnId)]
    ).

lock_difficulty(bronze_key, 12).
lock_difficulty(iron_key, 15).
lock_difficulty(steel_key, 18).
lock_difficulty(golden_key, 22).
lock_difficulty(master_key, 25).
lock_difficulty(_, 15).

step_pick(W, Id, DirQuery, NW, Evts) :-
    move:resolve_dir(DirQuery, Dir),
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    ( get_dict(locked_exits, N, Ls), member(Dir, Ls),
      get_dict(locks, N, Locks), get_dict(Dir, Locks, Key),
      inv(A, Inv), inv_rem(Inv, lockpick, 1, NInv)
    ->
        stat(A, dex, Dex), stat(A, luk, Luk),
        skill_val(A, lockpicking, Lvl), lock_difficulty(Key, DC),
        random_between(1, 20, Roll),
        ( Roll + Dex + floor(Lvl * 0.1) + floor(Luk * 0.3) >= DC ->
            select(Dir, Ls, NLs), NN = N.put(locked_exits, NLs),
            skill_mod(A, lockpicking, 1, NA),
            world:update(W, NA.put(inv, NInv), W1), update_room(W1, NN, NW),
            NLvl is Lvl + 1, Evts = [picked_lock(Id, Dir), skill_up(Id, lockpicking, NLvl)]
        ;
            BreakChance is max(10, 50 - floor(Luk * 0.5)), random_between(1, 100, BreakRoll),
            ( BreakRoll =< BreakChance ->
                world:update(W, A.put(inv, NInv), NW), Evts = [pick_failed(Id, Dir), pick_broken(Id)]
            ; NW = W, Evts = [pick_failed(Id, Dir)] )
        )
    ;
        NW = W, Evts = [cannot_pick(Id, DirQuery)]
    ).
