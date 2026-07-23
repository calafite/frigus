:- module(alchemy, [step_brew/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_alchemy).
:- use_module(status).

has_ingredients(_, []).
has_ingredients(Inv, [H|T]) :-
    ( member(stack{tag: H, qty: Q}, Inv), Q >= 1
    ; member(Item, Inv), is_dict(Item, item), Item.tag == H ), !,
    inv_rem(Inv, H, 1, TmpInv),
    has_ingredients(TmpInv, T).

remove_all(Inv, [], Inv).
remove_all(Inv, [H|T], NInv) :-
    ( inv_rem(Inv, H, 1, Tmp) -> true ; Tmp = Inv ),
    remove_all(Tmp, T, NInv).

get_aspects([], []).
get_aspects([H|T], Aspects) :-
    ( cfg_alchemy:ingredient_aspect(H, A) -> true ; A = junk ),
    get_aspects(T, Rest),
    ( is_list(A) -> append(A, Rest, Aspects) ; Aspects = [A|Rest] ).

match_recipe(Aspects, Potion) :-
    msort(Aspects, SortedA), cfg_alchemy:potion_recipe(ReqA, Potion),
    msort(ReqA, SortedReq), SortedA == SortedReq, !.
match_recipe(_, ruined_potion).

step_brew(W, Id, Ingredients, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), ( get_dict(props, N, Props) -> true ; Props = [] ), \+ member(laboratory, Props) ->
        NW = W, Evts = [missing_station(Id, laboratory)]
    ; inv(A, Inv), \+ (member(stack{tag: glass_vial, qty: Q}, Inv), Q >= 1), \+ (member(Item, Inv), is_dict(Item, item), Item.tag == glass_vial) ->
        NW = W, Evts = [missing_vial(Id)]
    ; inv(A, Inv), \+ has_ingredients(Inv, Ingredients) ->
        NW = W, Evts = [missing_ingredients(Id, brewing)]
    ;
        inv(A, Inv),
        remove_all(Inv, Ingredients, Inv1),
        inv_rem(Inv1, glass_vial, 1, Inv2),
        skill_val(A, alchemy, Lvl), stat(A, wis, Wis), stat(A, luk, Luk),
        get_aspects(Ingredients, Aspects), match_recipe(Aspects, Output),
        random_between(1, 100, Roll),
        ( Roll + Lvl + floor(Wis * 0.5) + floor(Luk * 0.3) >= 20 ->
            inv_add(Inv2, Output, 1, NInv),
            ( Lvl < 100, random_between(1, 100, R2), R2 =< (25 + floor(Luk * 0.2)) ->
                skill_mod(A, alchemy, 1, A1), NLvl is Lvl + 1,
                world:update(W, A1.put(inv, NInv), NW),
                Evts = [brewed(Id, Output), skill_up(Id, alchemy, NLvl)]
            ; world:update(W, A.put(inv, NInv), NW), Evts = [brewed(Id, Output)] )
        ;
            inv_add(Inv2, ruined_potion, 1, NInv),
            world:update(W, A.put(inv, NInv), NW),
            Evts = [brew_failed(Id, Output)]
        )
    ).
