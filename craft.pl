:- module(craft, [step_craft/5]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(cfg_craft).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_craft(W, Id, Output, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    cfg_craft:recipe(Output, Qty, Skill, MinLvl, Ingredients),
    room(A, RId), world:node(W, RId, N), cfg_craft:station(Skill, Prop), member(Prop, N.props),
    skill_val(A, Skill, Lvl), Lvl >= MinLvl,
    inv(A, Inv), check_ingredients(Inv, Ingredients), consume_ingredients(Inv, Ingredients, Inv1),
    inv_add(Inv1, Output, Qty, Inv2), inv(A, Inv2, A1),
    stat(A, luk, Luk), random_between(1, 100, Roll),
    ( Roll =< (10 + floor(Luk * 0.2)), Lvl < 100 ->
        skill_mod(A1, Skill, 1, A2), NLvl is Lvl + 1,
        Evts = [crafted(Id, Output, Qty), skill_up(Id, Skill, NLvl)]
    ; A2 = A1, Evts = [crafted(Id, Output, Qty)] ),
    world:update(W, A2, NW).

check_ingredients(_, []).
check_ingredients(Inv, [stack{tag: Tag, qty: Req}|T]) :-
    member(stack{tag: Tag, qty: Cur}, Inv), Cur >= Req, check_ingredients(Inv, T).

consume_ingredients(Inv, [], Inv).
consume_ingredients(Inv, [stack{tag: Tag, qty: Req}|T], NInv) :-
    inv_rem(Inv, Tag, Req, TmpInv), consume_ingredients(TmpInv, T, NInv).
