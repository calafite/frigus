:- module(item, [step_loot/5, step_equip/5]).

:- use_module(config).
:- use_module(entity).
:- use_module(world).

step_loot(W, Id, IId, NW, [looted(Id, Tag)]) :-
    world:entity(W, Id, A),
    alive(A),
    room(A, RId),
    world:entity(W, IId, I),
    room(I, RId),
    Tag = I.tag,
    inv(A, Inv),
    inv(A, [Tag | Inv], NA),
    world:remove(W, IId, TW),
    world:update(TW, NA, NW).

step_equip(W, Id, Tag, NW, [equipped(Id, Tag, Slot)]) :-
    world:entity(W, Id, A),
    alive(A),
    inv(A, Inv),
    select(Tag, Inv, TmpInv),
    slot(Tag, Slot),
    equip(A, Eq),
    get_dict(Slot, Eq, Old),
    NEq = Eq.put(Slot, Tag),
    equip(A, NEq, TmpA),
    ( Old == none -> NInv = TmpInv ; NInv = [Old | TmpInv] ),
    inv(TmpA, NInv, NA),
    world:update(W, NA, NW).
