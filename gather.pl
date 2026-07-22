:- module(gather, [step_gather/5, step_skin/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_gather).
:- use_module(status).
:- use_module(zone).

step_gather(W, Id, NodeId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    room(A, RId), world:node(W, RId, N),
    get_dict(nodes, N, Nodes), get_dict(NodeId, Nodes, Node),
    cfg_gather:node_yield(Node.tag, Out, Tool, Skill),
    ( Tool == none -> true ; (inv(A, Inv), member(stack{tag: Tool, qty: _}, Inv)) ),
    skill_val(A, Skill, Lvl), stat(A, luk, Luk),
    random_between(1, 100, Roll),
    ( Roll + Lvl + floor(Luk * 0.3) >= 15 ->
        random_between(1, 3, BaseYield),
        Yield is BaseYield + floor(Luk * 0.1),
        inv(A, InvA), inv_add(InvA, Out, Yield, NInv),
        A1 = A.put(inv, NInv),
        NNodes = Nodes.put(NodeId, Node.put(qty, Node.qty - 1)),
        ( NNodes.NodeId.qty =< 0 -> del_dict(NodeId, NNodes, _, FNodes), Evt = [gathered(Id, Out, Yield), depleted(NodeId)]
        ; FNodes = NNodes, Evt = [gathered(Id, Out, Yield)] ),
        NN = N.put(nodes, FNodes),
        world:update(W, A1, W1), zone:update_room(W1, NN, NW),
        ( Lvl < 100, random_between(1, 100, R2), R2 =< (20 + floor(Luk * 0.2)) ->
            NLvl is Lvl + 1, skill_mod(A1, Skill, 1, A2), world:update(NW, A2, NW2),
            Evts = [skill_up(Id, Skill, NLvl) | Evt], NW = NW2
        ; Evts = Evt )
    ; NW = W, Evts = [gather_failed(Id, NodeId)] ).

step_skin(W, Id, CorpseId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    inv(A, Inv), member(stack{tag: skinning_knife, qty: _}, Inv),
    room(A, RId), world:entity(W, CorpseId, Corpse), room(Corpse, RId),
    Corpse.tag == corpse, get_dict(mob_tag, Corpse, MobTag),
    cfg_gather:skin_yield(MobTag, Out, BaseYield),
    skill_val(A, skinning, Lvl), stat(A, dex, Dex), stat(A, luk, Luk),
    random_between(1, 100, Roll),
    ( Roll + Lvl + floor(Dex * 0.5) + floor(Luk * 0.2) >= 15 ->
        Yield is BaseYield + floor(Lvl * 0.1) + floor(Luk * 0.1),
        inv_add(Inv, Out, Yield, NInv),
        world:remove(W, CorpseId, W1),
        world:update(W1, A.put(inv, NInv), NW),
        ( Lvl < 100, random_between(1, 100, R2), R2 =< (20 + floor(Luk * 0.2)) ->
            NLvl is Lvl + 1, skill_mod(A.put(inv, NInv), skinning, 1, A2), world:update(NW, A2, NW2),
            Evts = [skinned(Id, Out, Yield), skill_up(Id, skinning, NLvl)], NW = NW2
        ; Evts = [skinned(Id, Out, Yield)] )
    ; world:remove(W, CorpseId, W1), NW = W1, Evts = [skin_failed_ruined(Id, CorpseId)] ).
