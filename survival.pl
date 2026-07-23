:- module(survival, [
    step_rest/4, step_sleep/4, step_wake/4, step_drink/5, step_fill/4,
    step_fish/4, step_fly/5, step_climb/4, step_mount/5, step_dismount/4,
    step_stance/5, tick_srv/5
]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

has_water_source(N) :-
    ( get_dict(props, N, Props) -> true ; Props = [] ),
    ( member(river, Props) ; member(fountain, Props) ; member(water, Props) ; member(shallow_water, Props) ; member(deep_water, Props) ; member(flooded, Props) ), !.

has_item(A, Tag) :-
    inv(A, Inv),
    ( member(stack{tag: Tag, qty: Q}, Inv), Q >= 1
    ; member(Item, Inv), is_dict(Item, item), Item.tag == Tag ), !.

step_rest(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ;
        A1 = A.put(state, resting),
        world:update(W, A1, NW),
        Evts = [started_resting(Id)]
    ).

step_sleep(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ;
        A1 = A.put(state, sleeping),
        world:update(W, A1, NW),
        Evts = [fell_asleep(Id)]
    ).

step_wake(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    A1 = A.put(state, normal),
    world:update(W, A1, NW),
    Evts = [woke_up(Id)].

step_drink(W, Id, ItemQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; (ItemQuery == none ; ItemQuery == "") ->
        room(A, RId), world:node(W, RId, N),
        ( has_water_source(N) ->
            ( get_dict(thirst, A, T) -> true ; T = 0 ),
            NT is max(0, T - 50),
            world:update(W, A.put(thirst, NT), NW),
            Evts = [drank_water(Id)]
        ; inv(A, Inv), (inv_rem(Inv, filled_waterskin, 1, NInv) ; inv_rem(Inv, water_skin, 1, NInv)) ->
            inv_add(NInv, empty_waterskin, 1, FinalInv),
            ( get_dict(thirst, A, T) -> true ; T = 0 ),
            NT is max(0, T - 50),
            world:update(W, A.put(inv, FinalInv).put(thirst, NT), NW),
            Evts = [drank_waterskin(Id)]
        ;
            NW = W, Evts = [no_water_source(Id)]
        )
    ; inv(A, Inv), (inv_rem(Inv, ItemQuery, 1, NInv) ; (ItemQuery == water_skin, inv_rem(Inv, filled_waterskin, 1, NInv))) ->
        ( (ItemQuery == filled_waterskin ; ItemQuery == water_skin) -> inv_add(NInv, empty_waterskin, 1, FinalInv) ; FinalInv = NInv ),
        ( get_dict(thirst, A, T) -> true ; T = 0 ),
        NT is max(0, T - 50),
        world:update(W, A.put(inv, FinalInv).put(thirst, NT), NW),
        Evts = [drank(Id, ItemQuery)]
    ;
        NW = W, Evts = [item_not_in_inv(Id, ItemQuery)]
    ).

step_fill(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), \+ has_water_source(N) ->
        NW = W, Evts = [no_water_source(Id)]
    ; inv(A, Inv), \+ has_item(A, empty_waterskin) ->
        NW = W, Evts = [missing_materials(Id, empty_waterskin)]
    ;
        inv(A, Inv), inv_rem(Inv, empty_waterskin, 1, NInv),
        inv_add(NInv, filled_waterskin, 1, FinalInv),
        world:update(W, A.put(inv, FinalInv), NW),
        Evts = [filled_waterskin(Id)]
    ).

step_fish(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), \+ has_water_source(N) ->
        NW = W, Evts = [no_water_source(Id)]
    ; \+ has_item(A, fishing_pole) ->
        NW = W, Evts = [missing_tool(Id, fishing_pole)]
    ;
        stat(A, dex, Dex), stat(A, luk, Luk),
        skill_val(A, fishing, Lvl),
        random_between(1, 100, Roll),
        ( Roll + floor(Dex * 0.4) + floor(Luk * 0.3) + Lvl >= 30 ->
            inv(A, Inv), inv_add(Inv, raw_fish, 1, NInv),
            ( Lvl < 100, random_between(1, 100, R2), R2 =< (25 + floor(Luk * 0.2)) ->
                skill_mod(A, fishing, 1, A1), NLvl is Lvl + 1,
                world:update(W, A1.put(inv, NInv), NW),
                Evts = [fished(Id, raw_fish), skill_up(Id, fishing, NLvl)]
            ; world:update(W, A.put(inv, NInv), NW), Evts = [fished(Id, raw_fish)] )
        ;
            NW = W, Evts = [fish_failed(Id)]
        )
    ).

step_fly(W, Id, Alt, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; props(A, P), (member(flight, P) ; member(griffin, P) ; race(A, angel) ; race(A, demigod)) ->
        A1 = A.put(altitude, Alt),
        world:update(W, A1, NW),
        Evts = [flying(Id, Alt)]
    ;
        NW = W, Evts = [cannot_fly(Id)]
    ).

step_climb(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ;
        A1 = A.put(climb_state, true),
        world:update(W, A1, NW),
        Evts = [climbing(Id)]
    ).

step_mount(W, Id, Mount, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ;
        A1 = A.put(mount, Mount),
        world:update(W, A1, NW),
        Evts = [mounted(Id, Mount)]
    ).

step_dismount(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    A1 = A.put(mount, none),
    world:update(W, A1, NW),
    Evts = [dismounted(Id)].

step_stance(W, Id, Stance, NW, Evts) :-
    world:entity(W, Id, A),
    A1 = A.put(stance, Stance),
    world:update(W, A1, NW),
    Evts = [stance_changed(Id, Stance)].

tick_srv(_W, _Id, E, NE, Evts) :-
    ( get_dict(state, E, State) -> true ; State = normal ),
    ( State == resting ->
        hp(E, Hp), get_dict(max_hp, E, MaxHp), NHp is min(MaxHp, Hp + 5),
        mp(E, Mp), get_dict(max_mp, E, MaxMp), NMp is min(MaxMp, Mp + 5),
        ( get_dict(fatigue, E, F) -> NF is max(0, F - 10) ; NF = 0 ),
        NE = E.put(hp, NHp).put(mp, NMp).put(fatigue, NF),
        Evts = []
    ; State == sleeping ->
        hp(E, Hp), get_dict(max_hp, E, MaxHp), NHp is min(MaxHp, Hp + 10),
        mp(E, Mp), get_dict(max_mp, E, MaxMp), NMp is min(MaxMp, Mp + 10),
        ( get_dict(fatigue, E, F) -> NF is max(0, F - 20) ; NF = 0 ),
        NE = E.put(hp, NHp).put(mp, NMp).put(fatigue, NF),
        Evts = []
    ;
        ( get_dict(hunger, E, H) -> NH is min(100, H + 1) ; NH = 1 ),
        ( get_dict(thirst, E, T) -> NT is min(100, T + 1) ; NT = 1 ),
        ( NH >= 100 -> hp(E, Hp), StarveHp is max(0, Hp - 2), StarveEvt = [starving(E.id)] ; StarveHp = E.hp, StarveEvt = [] ),
        ( NT >= 100 -> NHp is max(0, StarveHp - 3), DehyEvt = [dehydrated(E.id)] ; NHp = StarveHp, DehyEvt = [] ),
        NE = E.put(hunger, NH).put(thirst, NT).put(hp, NHp),
        append(StarveEvt, DehyEvt, Evts)
    ), !.
tick_srv(_, _, E, E, []).
