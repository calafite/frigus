:- module(item, [step_loot/5, step_equip/5, step_unequip/5, step_use/5]).

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

find_room_item(W, RId, Target, Item) :-
    world:entity(W, Target, Item), get_dict(room, Item, RId), !.
find_room_item(W, RId, Target, Item) :-
    world:room_entities(W, RId, Ents),
    member(Item, Ents), is_dict(Item, item),
    ( Target == "" ; Target == none ; Item.id == Target ; Item.tag == Target ;
      (get_dict(name, Item, Name), string_lower(Name, LName), string_lower(Target, LTarget), sub_string(LName, _, _, _, LTarget))
    ), !.

resolve_inventory_item(A, Query, Item) :-
    inv(A, Inv),
    ( member(Item, Inv), is_dict(Item, item), Item.id == Query
    ; member(Item, Inv), is_dict(Item, item), Item.tag == Query
    ; member(stack{tag: Tag, qty: _}, Inv), Tag == Query, Item = Tag
    ; member(Item, Inv), is_dict(Item, item), get_dict(name, Item, Name), string_lower(Name, LName), string_lower(Query, LQuery), sub_string(LName, _, _, _, LQuery)
    ), !.

step_loot(W, Id, Target, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), find_room_item(W, RId, Target, I) ->
        IId = I.id, Tag = I.tag, Qty = I.qty,
        ( config:weight(Tag, Wt) -> true ; Wt = 1.0 ),
        inv(A, Inv), inv_wt(Inv, CurWt), max_wt(A, MaxWt),
        ( CurWt + (Wt * Qty) =< MaxWt ->
            inv_add(Inv, Tag, Qty, NInv), inv(A, NInv, NA),
            world:remove(W, IId, TW), world:update(TW, NA, NW),
            Evts = [looted(Id, Tag, Qty)]
        ;
            NW = W, Evts = [too_heavy(Id, Tag)]
        )
    ;
        NW = W, Evts = [item_not_found(Id, Target)]
    ).

step_equip(W, Id, Target, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; resolve_inventory_item(A, Target, ItemRef) ->
        ( is_dict(ItemRef, item) -> Tag = ItemRef.tag ; Tag = ItemRef ),
        ( slot(Tag, Slot), Slot \== none ->
            config:req(Tag, ReqStat, ReqVal),
            ( ReqStat == none -> ReqOK = true ; stat(A, ReqStat, Val), Val >= ReqVal -> ReqOK = true ; ReqOK = false ),
            ( ReqOK == true ->
                inv(A, Inv), inv_rem(Inv, Tag, 1, TmpInv),
                equip(A, Eq), get_dict(Slot, Eq, Old),
                NEq = Eq.put(Slot, Tag), equip(A, NEq, TmpA),
                ( Old == none -> NInv = TmpInv ; inv_add(TmpInv, Old, 1, NInv) ),
                inv(TmpA, NInv, NA), world:update(W, NA, NW),
                Evts = [equipped(Id, Tag, Slot)]
            ;
                NW = W, Evts = [req_not_met(Id, ReqStat, ReqVal)]
            )
        ;
            NW = W, Evts = [not_equippable(Id, Tag)]
        )
    ;
        NW = W, Evts = [item_not_in_inv(Id, Target)]
    ).

step_unequip(W, Id, SlotQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ;
        ( SlotQuery == weapon -> Slot = wpn ; SlotQuery == armor -> Slot = body ; Slot = SlotQuery ),
        equip(A, Eq),
        ( get_dict(Slot, Eq, Item), Item \== none ->
            ( is_dict(Item, item) -> Tag = Item.tag ; Tag = Item ),
            NEq = Eq.put(Slot, none), equip(A, NEq, A1),
            inv(A1, Inv), inv_add(Inv, Tag, 1, NInv), inv(A1, NInv, NA),
            world:update(W, NA, NW),
            Evts = [unequipped(Id, Tag, Slot)]
        ;
            NW = W, Evts = [slot_empty(Id, Slot)]
        )
    ).

step_use(W, Id, Target, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; resolve_inventory_item(A, Target, ItemRef) ->
        ( is_dict(ItemRef, item) -> Tag = ItemRef.tag ; Tag = ItemRef ),
        ( (config:consumable(Tag, Effect) ; edible(Tag, Effect)) ->
            inv(A, Inv), inv_rem(Inv, Tag, 1, NInv),
            apply_eff(Effect, A, TmpA, EffEvts),
            inv(TmpA, NInv, NA), world:update(W, NA, NW),
            Evts = [used(Id, Tag, Effect) | EffEvts]
        ;
            NW = W, Evts = [not_usable(Id, Tag)]
        )
    ;
        NW = W, Evts = [item_not_in_inv(Id, Target)]
    ).

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
