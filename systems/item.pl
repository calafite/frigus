:- module(item, [do_loot/3, do_equip/3, do_unequip/3, do_use/3]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('../config/item').

resolve_room_item(RoomId, Query, Item) :-
    world:room_entities(RoomId, Ents),
    member(Item, Ents),
    is_dict(Item, item),
    ( get_dict(id, Item, Query) ; get_dict(tag, Item, Query) ), !.

do_loot(Id, _TgtQuery, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_loot(Id, TgtQuery, Evts) :-
    world:get_entity(Id, Actor),
    get_dict(room, Actor, Room),
    resolve_room_item(Room, TgtQuery, Item), !,
    get_dict(id, Item, ItemId),
    get_dict(tag, Item, Tag),
    get_dict(qty, Item, Qty),
    entity:add_item(Actor, Tag, Qty, NActor),
    world:put_entity(NActor),
    world:del_entity(ItemId),
    Evts = [looted(Id, Tag, Qty)].

do_loot(Id, TgtQuery, [error(item_not_found(Id, TgtQuery))]) :-
    world:get_entity(Id, _).

do_equip(Id, _Tag, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_equip(Id, Tag, Evts) :-
    world:get_entity(Id, Actor),
    entity:has_item(Actor, Tag),
    item_config:slot(Tag, Slot), Slot \== none, !,
    get_dict(equip, Actor, Eq),
    get_dict(Slot, Eq, OldTag),
    NEq = Eq.put(Slot, Tag),
    entity:rem_item(Actor, Tag, 1, TmpAct),
    ( OldTag == none ->
        NActor = TmpAct.put(equip, NEq)
    ;
        entity:add_item(TmpAct, OldTag, 1, NActor_WOld),
        NActor = NActor_WOld.put(equip, NEq)
    ),
    world:put_entity(NActor),
    Evts = [equipped(Id, Tag, Slot)].

do_equip(Id, Tag, [error(cannot_equip(Id, Tag))]) :-
    world:get_entity(Id, _).

do_unequip(Id, _SlotStr, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_unequip(Id, SlotStr, Evts) :-
    world:get_entity(Id, Actor),
    atom_string(Slot, SlotStr),
    get_dict(equip, Actor, Eq),
    get_dict(Slot, Eq, Tag), Tag \== none, !,
    NEq = Eq.put(Slot, none),
    entity:add_item(Actor, Tag, 1, TmpAct),
    NActor = TmpAct.put(equip, NEq),
    world:put_entity(NActor),
    Evts = [unequipped(Id, Tag, Slot)].

do_unequip(Id, SlotStr, [error(slot_empty(Id, SlotStr))]) :-
    world:get_entity(Id, _).

do_use(Id, _Tag, [error(actor_not_found(Id))]) :-
    \+ world:get_entity(Id, _), !.

do_use(Id, Tag, Evts) :-
    world:get_entity(Id, Actor),
    entity:has_item(Actor, Tag),
    item_config:consumable(Tag, Effect), !,
    entity:rem_item(Actor, Tag, 1, TmpAct),
    apply_effect(Effect, TmpAct, NActor),
    world:put_entity(NActor),
    Evts = [used(Id, Tag, Effect)].

do_use(Id, Tag, [error(cannot_use(Id, Tag))]) :-
    world:get_entity(Id, _).

apply_effect(heal(Amt), A, NA) :- entity:mod_hp(A, Amt, NA).
apply_effect(restore_mp(Amt), A, NA) :-
    get_dict(mp, A, Mp), get_dict(max_mp, A, Max),
    NMp is min(Max, Mp + Amt),
    NA = A.put(mp, NMp).
