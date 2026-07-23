:- module(interact, [step_pull/5, step_disarm/4, step_ignite/4]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_pull(W, Id, Sw, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), get_dict(switches, N, Sws), member(Sw, Sws) ->
        world:flags(W, Fs),
        NFs = Fs.put(Sw, true),
        world:flags(W, NFs, NW),
        Evts = [pulled(Id, Sw)]
    ;
        NW = W, Evts = [switch_not_found(Id, Sw)]
    ).

del_trap(N, NN) :-
    ( del_dict(trap, N, _, N1) -> true ; N1 = N ),
    ( del_dict(trap_inflicts, N1, _, NN) -> true ; NN = N1 ), !.

step_disarm(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), get_dict(trap, N, Dmg) ->
        stat(A, dex, Dex),
        random_between(1, 20, Roll),
        Score is Roll + Dex,
        DC is 10 + Dmg,
        ( Score >= DC ->
            del_trap(N, NN),
            world:update(W, NN, NW),
            Evts = [disarmed(Id, RId)]
        ;
            hp(A, Hp), NHp is max(0, Hp - Dmg),
            hp(A, NHp, A1),
            world:update(W, A1, NW),
            Evts = [disarm_failed(Id, RId, Dmg)]
        )
    ;
        room(A, RId), NW = W, Evts = [no_trap_found(Id, RId)]
    ).

has_item(A, Tag) :-
    inv(A, Inv),
    ( member(stack{tag: Tag, qty: Q}, Inv), Q >= 1
    ; member(Item, Inv), is_dict(Item, item), Item.tag == Tag ), !.

step_ignite(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; \+ has_item(A, flint_and_steel) ->
        NW = W, Evts = [missing_tool(Id, flint_and_steel)]
    ; \+ has_item(A, timber) ->
        NW = W, Evts = [missing_materials(Id, campfire)]
    ;
        inv(A, Inv), inv_rem(Inv, timber, 1, NInv),
        room(A, RId), world:node(W, RId, N),
        ( get_dict(props, N, Props) -> true ; Props = [] ),
        ( member(dark, Props) ->
            select(dark, Props, Rest),
            NProps = [campfire(30), originally_dark | Rest],
            IgniteEvts = [ignited_campfire(Id, RId), room_lit(RId)]
        ; \+ member(campfire(_), Props) ->
            NProps = [campfire(30) | Props],
            IgniteEvts = [ignited_campfire(Id, RId)]
        ;
            NProps = Props,
            IgniteEvts = [campfire_already_lit(Id, RId)]
        ),
        NN = N.put(props, NProps),
        world:update(W, A.put(inv, NInv), W1),
        world:update(W1, NN, NW),
        Evts = IgniteEvts
    ).
