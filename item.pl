:- module(item, [step_loot/5, step_equip/5, step_use/5]).

:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

get_val(K, E, _D, V) :- get_dict(K, E, V), !.
get_val(_, _, D, D).

edible(cooked_fish, food(40)).
edible(cooked_meat, food(40)).
edible(cooked_steak, food(60)).
edible(cooked_chop, food(50)).
edible(cooked_mutton, food(50)).
edible(cooked_beef, food(60)).
edible(bread, food(30)).
edible(apple_pie, food(50)).
edible(meat_pie, food(60)).
edible(cookie, food(20)).

edible(poisoned_cooked_fish, poisoned_food(40, poison)).
edible(poisoned_cooked_meat, poisoned_food(40, poison)).
edible(poisoned_cooked_steak, poisoned_food(60, poison)).
edible(poisoned_cooked_chop, poisoned_food(50, poison)).
edible(poisoned_cooked_mutton, poisoned_food(50, poison)).
edible(poisoned_cooked_beef, poisoned_food(60, poison)).
edible(poisoned_bread, poisoned_food(30, poison)).
edible(poisoned_apple_pie, poisoned_food(50, poison)).
edible(poisoned_meat_pie, poisoned_food(60, poison)).
edible(poisoned_cookie, poisoned_food(20, poison)).

step_loot(W, Id, IId, NW, [looted(Id, Tag, Qty)]) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
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
    status:can_act(A),
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

step_use(W, Id, Tag, NW, [used(Id, Tag, Effect) | Evts]) :-
    world:entity(W, Id, A), alive(A),
    status:can_act(A),
    inv(A, Inv), inv_rem(Inv, Tag, 1, NInv),
    ( config:consumable(Tag, Effect) -> true
    ; edible(Tag, Effect) -> true ),
    apply_eff(Effect, A, TmpA, Evts),
    inv(TmpA, NInv, NA),
    world:update(W, NA, NW).

apply_eff(heal(Amt), A, NA, []) :-
    hp(A, Hp),
    NHp is Hp + Amt,
    hp(A, NHp, NA).
apply_eff(buff(Stat, Val, Dur), A, NA, Evts) :-
    status:apply_aff(A, aff{type: buff, stat: Stat, val: Val, dur: Dur}, NA, Evts).
apply_eff(food(Amt), A, NA, []) :-
    get_val(hunger, A, 0, H),
    NH is max(0, H - Amt),
    NA = A.put(hunger, NH).
apply_eff(drink(Amt), A, NA, []) :-
    get_val(thirst, A, 0, T),
    NT is max(0, T - Amt),
    NA = A.put(thirst, NT).
apply_eff(poisoned_food(Amt, Poison), A, NA, Evts) :-
    get_val(hunger, A, 0, H),
    NH is max(0, H - Amt),
    status:apply_aff(A.put(hunger, NH), aff{type: Poison, val: 5, dur: 5}, NA, Evts).
