:- module(gather, [step_gather/5, step_skin/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_gather).
:- use_module(status).

find_room_node(N, Query, RealNodeId, Node) :-
    get_dict(nodes, N, Nodes),
    ( get_dict(Query, Nodes, Node) -> RealNodeId = Query
    ; dict_pairs(Nodes, _, Pairs),
      member(RealNodeId-Node, Pairs),
      ( get_dict(tag, Node, Tag), Tag == Query )
    ), !.

has_tool(_A, none) :- !.
has_tool(A, Tool) :-
    inv(A, Inv),
    ( member(stack{tag: Tool, qty: Q}, Inv), Q >= 1
    ; member(Item, Inv), is_dict(Item, item), Item.tag == Tool ), !.

step_gather(W, Id, NodeQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), find_room_node(N, NodeQuery, NodeId, Node) ->
        get_dict(nodes, N, Nodes),
        cfg_gather:node_yield(Node.tag, Out, Tool, Skill),
        ( has_tool(A, Tool) ->
            skill_val(A, Skill, Lvl), stat(A, luk, Luk),
            random_between(1, 100, Roll),
            ( Roll + Lvl + floor(Luk * 0.3) >= 15 ->
                random_between(1, 3, BaseYield),
                Yield is BaseYield + floor(Luk * 0.1),
                inv(A, InvA), inv_add(InvA, Out, Yield, NInv),
                A1 = A.put(inv, NInv),
                RemQty is Node.qty - 1,
                ( RemQty =< 0 ->
                    del_dict(NodeId, Nodes, _, FNodes),
                    Evt = [gathered(Id, Out, Yield), depleted(NodeId)]
                ;
                    FNodes = Nodes.put(NodeId, Node.put(qty, RemQty)),
                    Evt = [gathered(Id, Out, Yield)]
                ),
                NN = N.put(nodes, FNodes),
                world:update(W, A1, W1), world:update(W1, NN, W2),
                ( Lvl < 100, random_between(1, 100, R2), R2 =< (20 + floor(Luk * 0.2)) ->
                    NLvl is Lvl + 1, skill_mod(A1, Skill, 1, A2), world:update(W2, A2, NW),
                    Evts = [skill_up(Id, Skill, NLvl) | Evt]
                ; NW = W2, Evts = Evt )
            ;
                NW = W, Evts = [gather_failed(Id, NodeId)]
            )
        ;
            NW = W, Evts = [missing_tool(Id, Tool)]
        )
    ;
        NW = W, Evts = [node_not_found(Id, NodeQuery)]
    ).

find_corpse(W, RId, Query, Corpse) :-
    world:room_entities(W, RId, Ents),
    member(Corpse, Ents), is_dict(Corpse, item), Corpse.tag == corpse,
    ( Query == "" ; Query == none ; Corpse.id == Query ; (get_dict(mob_tag, Corpse, MT), MT == Query) ), !.

step_skin(W, Id, CorpseQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; \+ has_tool(A, skinning_knife) ->
        NW = W, Evts = [missing_tool(Id, skinning_knife)]
    ; room(A, RId), find_corpse(W, RId, CorpseQuery, Corpse) ->
        CorpseId = Corpse.id,
        get_dict(mob_tag, Corpse, MobTag),
        cfg_gather:skin_yield(MobTag, Out, BaseYield),
        skill_val(A, skinning, Lvl), stat(A, dex, Dex), stat(A, luk, Luk),
        random_between(1, 100, Roll),
        ( Roll + Lvl + floor(Dex * 0.5) + floor(Luk * 0.2) >= 15 ->
            Yield is BaseYield + floor(Lvl * 0.1) + floor(Luk * 0.1),
            inv(A, Inv), inv_add(Inv, Out, Yield, NInv),
            world:remove(W, CorpseId, W1),
            A1 = A.put(inv, NInv),
            world:update(W1, A1, W2),
            ( Lvl < 100, random_between(1, 100, R2), R2 =< (20 + floor(Luk * 0.2)) ->
                NLvl is Lvl + 1, skill_mod(A1, skinning, 1, A2), world:update(W2, A2, NW),
                Evts = [skinned(Id, Out, Yield), skill_up(Id, skinning, NLvl)]
            ; NW = W2, Evts = [skinned(Id, Out, Yield)] )
        ;
            world:remove(W, CorpseId, NW),
            Evts = [skin_failed_ruined(Id, CorpseId)]
        )
    ;
        NW = W, Evts = [corpse_not_found(Id, CorpseQuery)]
    ).
