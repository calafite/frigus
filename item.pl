:- module(item, [step_loot/5, step_equip/5, step_use/5]).

:- use_module(config).
:- use_module(entity).
:- use_module(world).

step_loot(W, Id, IId, NW, [looted(Id, Tag, Qty)]) :-
    world:entity(W, Id, A),
    alive(A),
    room(A, RId),
    world:entity(W, IId, I),
    room(I, RId),
    Tag = I.tag,
    Qty = I.qty,
    config:weight(Tag, Wt),
    inv(A, Inv),
    inv_wt(Inv, CurWt),
    max_wt(A, MaxWt),
    CurWt + (Wt * Qty) =< MaxWt,
    inv_add(Inv, Tag, Qty, NInv),
    inv(A, NInv, NA),
    world:remove(W, IId, TW),
    world:update(TW, NA, NW).

step_equip(W, Id, Tag, NW, [equipped(Id, Tag, Slot)]) :-
    world:entity(W, Id, A),
    alive(A),
    config:req(Tag, ReqStat, ReqVal),
    stat(A, ReqStat, Val),
    Val >= ReqVal,
    inv(A, Inv),
    inv_rem(Inv, Tag, 1, TmpInv),
    slot(Tag, Slot),
    equip(A, Eq),
    get_dict(Slot, Eq, Old),
    NEq = Eq.put(Slot, Tag),
    equip(A, NEq, TmpA),
    ( Old == none -> NInv = TmpInv ; inv_add(TmpInv, Old, 1, NInv) ),
    inv(TmpA, NInv, NA),
    world:update(W, NA, NW).

step_use(W, Id, Tag, NW, [used(Id, Tag, Effect)]) :-
    world:entity(W, Id, A),
    alive(A),
    inv(A, Inv),
    inv_rem(Inv, Tag, 1, NInv),
    config:consumable(Tag, Effect),
    apply_eff(Effect, A, TmpA),
    inv(TmpA, NInv, NA),
    world:update(W, NA, NW).

apply_eff(heal(Amt), A, NA) :-
    hp(A, Hp),
    NHp is Hp + Amt,
    hp(A, NHp, NA).
