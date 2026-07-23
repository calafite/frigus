:- module(craft, [step_craft/5, check_ingredients/2, consume_ingredients/3]).

:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(cfg_craft).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

step_craft(W, Id, Output, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; \+ cfg_craft:recipe(Output, _, _, _, _) ->
        NW = W, Evts = [unknown_recipe(Id, Output)]
    ;
        cfg_craft:recipe(Output, Qty, Skill, MinLvl, Ingredients),
        room(A, RId), world:node(W, RId, N),
        ( get_dict(props, N, Props) -> true ; Props = [] ),
        ( cfg_craft:station(Skill, Prop), member(Prop, Props) -> HasStation = true ; HasStation = false ),
        ( HasStation == false ->
            NW = W, Evts = [missing_station(Id, Skill)]
        ; skill_val(A, Skill, Lvl), Lvl < MinLvl ->
            NW = W, Evts = [craft_skill_too_low(Id, Skill, MinLvl)]
        ; inv(A, Inv), \+ check_ingredients(Inv, Ingredients) ->
            NW = W, Evts = [missing_ingredients(Id, Output)]
        ;
            inv(A, Inv), consume_ingredients(Inv, Ingredients, Inv1),
            inv_add(Inv1, Output, Qty, Inv2), inv(A, Inv2, A1),
            stat(A, luk, Luk), skill_val(A, Skill, Lvl),
            random_between(1, 100, Roll),
            ( Roll =< (10 + floor(Luk * 0.2)), Lvl < 100 ->
                skill_mod(A1, Skill, 1, A2), NLvl is Lvl + 1,
                Evts = [crafted(Id, Output, Qty), skill_up(Id, Skill, NLvl)]
            ; A2 = A1, Evts = [crafted(Id, Output, Qty)] ),
            world:update(W, A2, NW)
        )
    ).

check_ingredients(_, []).
check_ingredients(Inv, [stack{tag: Tag, qty: Req}|T]) :-
    count_ingred_qty(Inv, Tag, Count), Count >= Req,
    check_ingredients(Inv, T).

count_ingred_qty([], _, 0).
count_ingred_qty([stack{tag: Tag, qty: Q}|T], Tag, Count) :- !,
    count_ingred_qty(T, Tag, Rest), Count is Q + Rest.
count_ingred_qty([Item|T], Tag, Count) :-
    is_dict(Item, item), Item.tag == Tag, !,
    count_ingred_qty(T, Tag, Rest), Count is 1 + Rest.
count_ingred_qty([_|T], Tag, Count) :-
    count_ingred_qty(T, Tag, Count).

consume_ingredients(Inv, [], Inv).
consume_ingredients(Inv, [stack{tag: Tag, qty: Req}|T], NInv) :-
    inv_rem(Inv, Tag, Req, TmpInv),
    consume_ingredients(TmpInv, T, NInv).
