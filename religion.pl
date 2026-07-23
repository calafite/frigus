:- module(religion, [step_pray/4, step_sacrifice/5]).

:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_deity).
:- use_module(status).

piety(E, Deity, Val) :- is_dict(E), get_dict(piety, E, P), is_dict(P), get_dict(Deity, P, Val), !.
piety(_, _, 0).

add_piety(E, Deity, Amt, NE) :-
    ( get_dict(piety, E, P), is_dict(P) ->
        ( get_dict(Deity, P, Cur) -> NVal is Cur + Amt ; NVal = Amt ),
        NP = P.put(Deity, NVal), NE = E.put(piety, NP)
    ;
        NE = E.put(piety, dict{}.put(Deity, Amt))
    ).

has_blessing(A, buff(Stat, Val, _)) :-
    affs(A, Affs), member(aff{type: buff, stat: Stat, val: Val, dur: 9999}, Affs).

find_room_altar(N, Altar, Deity) :-
    ( get_dict(props, N, Props) -> true ; Props = [] ),
    member(Altar, Props),
    cfg_deity:altar(Altar, Deity), !.

step_pray(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), find_room_altar(N, _Altar, Deity) ->
        piety(A, Deity, PVal),
        ( cfg_deity:blessing(Deity, Req, Buff), PVal >= Req, \+ has_blessing(A, Buff) ->
            status:apply_aff(A, Buff, NA, AEvts), add_piety(NA, Deity, -Req, NA2),
            world:update(W, NA2, NW), Evts = [blessed(Id, Deity) | AEvts]
        ;
            NW = W, Evts = [prayed(Id, Deity)]
        )
    ;
        room(A, RId), NW = W, Evts = [no_altar(Id, RId)]
    ).

find_sacrifice_item(A, ItemQuery, Tag, CostItem) :-
    inv(A, Inv),
    ( member(Item, Inv), is_dict(Item, item), Item.id == ItemQuery ->
        Tag = Item.tag, CostItem = ItemQuery
    ; member(Item, Inv), is_dict(Item, item), Item.tag == ItemQuery ->
        Tag = Item.tag, CostItem = ItemQuery
    ; member(stack{tag: Tag, qty: Q}, Inv), Tag == ItemQuery, Q >= 1 ->
        CostItem = ItemQuery
    ; member(Item, Inv), is_dict(Item, item), get_dict(name, Item, Name), string_lower(Name, LName), string_lower(ItemQuery, LQ), sub_string(LName, _, _, _, LQ) ->
        Tag = Item.tag, CostItem = Item.id
    ), !.

step_sacrifice(W, Id, ItemQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), find_room_altar(N, _Altar, Deity) ->
        ( find_sacrifice_item(A, ItemQuery, Tag, CostItem), inv(A, Inv), inv_rem(Inv, CostItem, 1, NInv) ->
            stat(A, cha, Cha), stat(A, luk, Luk),
            ( cfg_deity:sac_val(Tag, BaseVal) -> true ; BaseVal = 1 ),
            Val is BaseVal + floor(Cha * 0.2) + floor(Luk * 0.1),
            add_piety(A, Deity, Val, NA),
            world:update(W, NA.put(inv, NInv), NW),
            Evts = [sacrificed(Id, Tag, Deity, Val)]
        ;
            NW = W, Evts = [item_not_in_inv(Id, ItemQuery)]
        )
    ;
        room(A, RId), NW = W, Evts = [no_altar(Id, RId)]
    ).
