:- module(enchant, [step_enchant/6, step_identify/5, step_repair/6]).

:- use_module(cfg_enchant).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_enchant(W, Id, ItemId, Rune, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), inv_rem(Inv, Rune, 1, Inv1),
    cfg_enchant:rune_stat(Rune, Stat, Val),
    select(Item, Inv1, Inv2), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props),
    \+ member(prop(Stat, _), Props),
    NItem = Item.put(props, [prop(Stat, Val)|Props]),
    world:update(W, A.put(inv, [NItem|Inv2]), NW),
    Evts = [enchanted(Id, ItemId, Rune, Stat, Val)].

step_identify(W, Id, ItemId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), inv_rem(Inv, scroll_of_identify, 1, Inv1),
    select(Item, Inv1, Inv2), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props),
    select(unidentified, Props, RestProps),
    NItem = Item.put(props, RestProps),
    world:update(W, A.put(inv, [NItem|Inv2]), NW),
    Evts = [identified(Id, ItemId, NItem.name)].

step_repair(W, Id, Slot, Kit, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), inv_rem(Inv, Kit, 1, NInv),
    cfg_enchant:repair_kit(Kit, Slot),
    equip(A, Eq), get_dict(Slot, Eq, Item), is_dict(Item, item),
    get_dict(props, Item, Props),
    select(durability(Cur, Max), Props, RestProps),
    Cur < Max,
    ( Kit == master_whetstone ; Kit == heavy_armor_kit -> NCur = Max
    ; NCur is min(Max, Cur + floor(Max * 0.3)) ),
    NItem = Item.put(props, [durability(NCur, Max)|RestProps]),
    NEq = Eq.put(Slot, NItem),
    world:update(W, A.put(inv, NInv).put(equip, NEq), NW),
    Evts = [repaired(Id, NItem.name, NCur, Max)].
