:- module(religion, [step_pray/4, step_sacrifice/5]).

:- use_module(entity).
:- use_module(world).
:- use_module(cfg_deity).
:- use_module(status).

piety(E, Deity, Val) :- get_dict(piety, E, P), get_dict(Deity, P, Val), !.
piety(_, _, 0).

add_piety(E, Deity, Amt, NE) :-
    get_dict(piety, E, P), !,
    ( get_dict(Deity, P, Cur) -> NVal is Cur + Amt ; NVal = Amt ),
    NP = P.put(Deity, NVal), NE = E.put(piety, NP).
add_piety(E, Deity, Amt, NE) :- NE = E.put(piety, dict{}.put(Deity, Amt)).

step_pray(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A), room(A, RId), world:node(W, RId, N),
    get_dict(props, N, Props), member(Altar, Props), cfg_deity:altar(Altar, Deity),
    piety(A, Deity, PVal),
    ( cfg_deity:blessing(Deity, Req, Buff), PVal >= Req, \+ has_blessing(A, Buff) ->
        status:apply_aff(A, Buff, NA, AEvts), add_piety(NA, Deity, -Req, NA2),
        world:update(W, NA2, NW), Evts = [blessed(Id, Deity) | AEvts]
    ; NW = W, Evts = [prayed(Id, Deity)] ).

has_blessing(A, buff(Stat, Val, _)) :-
    affs(A, Affs), member(aff{type: buff, stat: Stat, val: Val, dur: 9999}, Affs).

step_sacrifice(W, Id, ItemId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), room(A, RId), world:node(W, RId, N),
    get_dict(props, N, Props), member(Altar, Props), cfg_deity:altar(Altar, Deity),
    inv(A, Inv),
    ( select(Item, Inv, _) , is_dict(Item, item), Item.id == ItemId ->
        Tag = Item.tag, CostItem = ItemId
    ;
        Tag = ItemId, CostItem = ItemId
    ),
    inv_rem(Inv, CostItem, 1, NInv),
    stat(A, cha, Cha), stat(A, luk, Luk),
    cfg_deity:sac_val(Tag, BaseVal), Val is BaseVal + floor(Cha * 0.2) + floor(Luk * 0.1),
    add_piety(A, Deity, Val, NA), world:update(W, NA.put(inv, NInv), NW),
    Evts = [sacrificed(Id, Tag, Deity, Val)].
