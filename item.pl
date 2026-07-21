:- module(item, [step_loot/5, step_equip/5]).

:- use_module(config).
:- use_module(entity).

step_loot(S, Id, IId, NS, [looted(Id, Tag)]) :-
    has(S, Id, A),
    alive(A),
    room(A, RId),
    has(S, IId, I),
    room(I, RId),
    Tag = I.tag,
    inv(A, Inv),
    inv(A, [Tag | Inv], NA),
    del(S, IId, TS),
    put(TS, Id, NA, NS).

step_equip(S, Id, Tag, NS, [equipped(Id, Tag, Slot)]) :-
    has(S, Id, A),
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
    put(S, Id, NA, NS).
