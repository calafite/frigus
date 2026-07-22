:- module(mud_socket, [step_socket/6]).

:- use_module(library(lists)).
:- use_module(cfg_socket).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_socket(W, Id, ItemId, GemTag, NW, [socketed(Id, ItemId, GemTag)]) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), inv_rem(Inv, GemTag, 1, Inv1),
    select(Item, Inv1, Inv2), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props),
    member(prop(sockets, Total), Props),
    findall(G, member(prop(socketed(G), 1), Props), Socketed),
    length(Socketed, Count), Count < Total,
    config:slot(Item.tag, Slot),
    ( cfg_socket:slot_group(Slot, Group) -> true ; Group = none ),
    cfg_socket:gem_effect(GemTag, Group, GemProp),
    NItem = Item.put(props, [GemProp, prop(socketed(GemTag), 1) | Props]),
    world:update(W, A.put(inv, [NItem|Inv2]), NW).
