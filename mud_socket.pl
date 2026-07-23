:- module(mud_socket, [step_socket/6]).

:- use_module(library(lists)).
:- use_module(cfg_socket).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

find_socket_item(Inv, Query, Item, RestInv) :-
    select(Item, Inv, RestInv), is_dict(Item, item),
    ( Item.id == Query
    ; Item.tag == Query
    ; (get_dict(name, Item, Name), string_lower(Name, LName), string_lower(Query, LQuery), sub_string(LName, _, _, _, LQuery))
    ), !.

step_socket(W, Id, ItemQuery, GemTag, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; inv(A, Inv), \+ (member(stack{tag: GemTag, qty: Q}, Inv), Q >= 1), \+ (member(GItem, Inv), is_dict(GItem, item), GItem.tag == GemTag) ->
        NW = W, Evts = [item_not_in_inv(Id, GemTag)]
    ; inv(A, Inv), \+ find_socket_item(Inv, ItemQuery, _, _) ->
        NW = W, Evts = [item_not_in_inv(Id, ItemQuery)]
    ;
        inv(A, Inv), inv_rem(Inv, GemTag, 1, Inv1),
        find_socket_item(Inv1, ItemQuery, Item, Inv2),
        ( get_dict(props, Item, Props) -> true ; Props = [] ),
        ( member(prop(sockets, Total), Props) -> HasSockets = true ; HasSockets = false ),
        ( HasSockets == false ->
            NW = W, Evts = [no_sockets_available(Id, Item.tag)]
        ;
            findall(G, member(prop(socketed(G), 1), Props), Socketed),
            length(Socketed, Count),
            ( Count >= Total ->
                NW = W, Evts = [sockets_full(Id, Item.tag)]
            ;
                config:slot(Item.tag, Slot),
                ( cfg_socket:slot_group(Slot, Group) -> true ; Group = none ),
                ( cfg_socket:gem_effect(GemTag, Group, GemProp) ->
                    NItem = Item.put(props, [GemProp, prop(socketed(GemTag), 1) | Props]),
                    world:update(W, A.put(inv, [NItem|Inv2]), NW),
                    Evts = [socketed(Id, Item.id, GemTag)]
                ;
                    NW = W, Evts = [invalid_gem(Id, GemTag)]
                )
            )
        )
    ).
