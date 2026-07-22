:- module(nature, [
    step_till/4, step_plant/5, step_harvest/4, tick_crops/3,
    step_tame/5, step_command/5, step_feed/5
]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_nature).

update_room(W, R, NW) :-
    select(O, W.rooms, Rest), O.id == R.id, !,
    NW = W.put(rooms, [R|Rest]).

step_till(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    inv(A, Inv), member(stack{tag: hoe, qty: _}, Inv),
    room(A, RId), world:node(W, RId, N),
    N.type == outdoor, \+ member(tilled, N.props),
    NN = N.put(props, [tilled|N.props]),
    update_room(W, NN, NW),
    Evts = [tilled_soil(Id, RId)].

step_plant(W, Id, Seed, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    inv(A, Inv), inv_rem(Inv, Seed, 1, NInv),
    cfg_nature:crop_data(Seed, Out, Max),
    room(A, RId), world:node(W, RId, N),
    member(tilled, N.props), \+ member(crop(_, _, _, _), N.props),
    NN = N.put(props, [crop(Id, Out, 0, Max)|N.props]),
    world:update(W, A.put(inv, NInv), W1),
    update_room(W1, NN, NW),
    Evts = [planted_seed(Id, Seed, RId)].

step_harvest(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    room(A, RId), world:node(W, RId, N),
    select(crop(Owner, Out, Cur, Max), N.props, Rest),
    Cur >= Max,
    ( Owner == Id ; Owner == none ),
    inv(A, Inv),
    stat(A, luk, Luk), stat(A, wis, Wis),
    random_between(1, 3, BaseYield),
    Yield is BaseYield + floor(Luk * 0.1) + floor(Wis * 0.1),
    inv_add(Inv, Out, Yield, NInv),
    NN = N.put(props, Rest),
    world:update(W, A.put(inv, NInv), W1),
    update_room(W1, NN, NW),
    Evts = [harvested(Id, Out, Yield)].

tick_crops(W, NW, Evts) :-
    get_dict(env, W, Env),
    ( Env.weath == rain -> GrowthMod = 2 ; GrowthMod = 1 ),
    findall(R, (member(R, W.rooms), member(crop(_, _, _, _), R.props)), CropRooms),
    grow_rooms(W, CropRooms, GrowthMod, NW, Evts).

grow_rooms(W, [], W, []).
grow_rooms(W, [R|Ts], Mod, NW, Evts) :-
    select(crop(Owner, Out, Cur, Max), R.props, Rest),
    ( Cur < Max ->
        NCur is Cur + Mod, FinalCur is min(Max, NCur),
        NR = R.put(props, [crop(Owner, Out, FinalCur, Max)|Rest]),
        ( FinalCur == Max -> Evt = [crop_matured(R.id, Out)] ; Evt = [] )
    ; NR = R, Evt = [] ),
    update_room(W, NR, W1),
    grow_rooms(W1, Ts, Mod, NW, REvts),
    append(Evt, REvts, Evts).

step_tame(W, Id, TgtId, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    world:entity(W, TgtId, T), alive(T),
    is_dict(T, mob), cfg_nature:tamable(T.tag, DC),
    \+ get_dict(master, T, _),
    stat(A, cha, Cha), stat(A, luk, Luk),
    random_between(1, 20, Roll),
    ( Roll + floor(Cha * 0.8) + floor(Luk * 0.2) >= DC ->
        T1 = T.put(master, Id).put(fac, A.fac),
        world:update(W, T1, NW),
        Evts = [tamed(Id, TgtId, T.tag)]
    ; Evts = [tame_failed(Id, TgtId)] ).

step_command(W, Id, PetId, Cmd, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    world:entity(W, PetId, Pet), alive(Pet),
    get_dict(master, Pet, Id),
    P1 = Pet.put(command, Cmd),
    world:update(W, P1, NW),
    Evts = [commanded_pet(Id, PetId, Cmd)].

step_feed(W, Id, PetId, NW, Evts) :-
    world:entity(W, Id, A), alive(A),
    world:entity(W, PetId, Pet), alive(Pet),
    get_dict(master, Pet, Id),
    cfg_nature:pet_food(Pet.tag, Food),
    inv(A, Inv), inv_rem(Inv, Food, 1, NInv),
    hp(Pet, Hp), get_dict(max_hp, Pet, MaxHp),
    NHp is min(MaxHp, Hp + floor(MaxHp * 0.2)),
    P1 = Pet.put(hp, NHp),
    world:update(W, A.put(inv, NInv), W1),
    world:update(W1, P1, NW),
    Evts = [fed_pet(Id, PetId, Food)].
