:- module(cooking, [step_cook/5, step_poison/6]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(zone).

recipe(cooked_fish, campfire, [raw_fish]).
recipe(cooked_meat, campfire, [raw_meat]).
recipe(cooked_steak, campfire, [venison]).
recipe(cooked_chop, campfire, [pork]).
recipe(cooked_mutton, campfire, [mutton]).
recipe(cooked_beef, campfire, [beef]).
recipe(stew, campfire, [raw_meat, potato, water_skin]).
recipe(bread, oven, [flour, water_skin]).
recipe(apple_pie, oven, [apple, flour, sugar]).
recipe(meat_pie, oven, [raw_meat, flour, egg]).
recipe(cookie, oven, [flour, sugar, butter]).

poison_version(cooked_fish, poisoned_cooked_fish).
poison_version(cooked_meat, poisoned_cooked_meat).
poison_version(cooked_steak, poisoned_cooked_steak).
poison_version(cooked_chop, poisoned_cooked_chop).
poison_version(cooked_mutton, poisoned_cooked_mutton).
poison_version(cooked_beef, poisoned_cooked_beef).
poison_version(bread, poisoned_bread).
poison_version(apple_pie, poisoned_apple_pie).
poison_version(meat_pie, poisoned_meat_pie).
poison_version(cookie, poisoned_cookie).

is_poison(spider_venom).
is_poison(poison).
is_poison(nightshade).

check_ingreds(_, []).
check_ingreds(Inv, [Tag|T]) :-
    ( member(stack{tag: Tag, qty: Q}, Inv), Q >= 1
    ; member(Item, Inv), is_dict(Item, item), Item.tag == Tag ),
    check_ingreds(Inv, T).

consume_ingreds(Inv, [], Inv).
consume_ingreds(Inv, [Tag|T], NInv) :- inv_rem(Inv, Tag, 1, Tmp), consume_ingreds(Tmp, T, NInv).

step_cook(W, Id, Output, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    recipe(Output, Station, Ingreds),
    room(A, RId), world:node(W, RId, N), ( member(Station, N.props) ; member(campfire(_), N.props) ),
    inv(A, Inv), check_ingreds(Inv, Ingreds), consume_ingreds(Inv, Ingreds, Inv1),
    skill_val(A, cooking, Lvl), stat(A, wis, Wis), stat(A, luk, Luk),
    random_between(1, 100, Roll),
    ( Roll + Lvl + floor(Wis * 0.2) + floor(Luk * 0.2) >= 15 ->
        inv_add(Inv1, Output, 1, Inv2),
        ( Lvl < 100, random_between(1, 100, R2), R2 =< (25 + floor(Luk * 0.2)) ->
            skill_mod(A, cooking, 1, A1), NLvl is Lvl + 1,
            Evts = [cooked(Id, Output), skill_up(Id, cooking, NLvl)]
        ; A1 = A, Evts = [cooked(Id, Output)] )
    ; inv_add(Inv1, burnt_food, 1, Inv2), A1 = A, Evts = [burnt_cooking(Id, Output)] ),
    world:update(W, A1.put(inv, Inv2), NW).

step_poison(W, Id, Food, Poison, NW, [poisoned_food(Id, Food, Poisoned)]) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    is_poison(Poison), poison_version(Food, Poisoned),
    inv(A, Inv), inv_rem(Inv, Food, 1, Inv1), inv_rem(Inv1, Poison, 1, Inv2),
    inv_add(Inv2, Poisoned, 1, Inv3), world:update(W, A.put(inv, Inv3), NW).
