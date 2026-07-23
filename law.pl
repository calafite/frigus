:- module(law, [step_pay_bounty/4, step_jailbreak/4, step_bribe_guard/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(move).
:- use_module(npc_life).
:- use_module(combat).

step_pay_bounty(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), ( get_dict(props, N, Props) -> true ; Props = [] ), \+ member(town_hall, Props) ->
        NW = W, Evts = [not_at_town_hall(Id, RId)]
    ; bounty(A, B), B =:= 0 ->
        NW = W, Evts = [no_bounty(Id)]
    ; bounty(A, B), B > 0, inv(A, Inv), \+ (member(stack{tag: gold, qty: G}, Inv), G >= B) ->
        NW = W, Evts = [insufficient_gold(Id, B)]
    ;
        bounty(A, B), inv(A, Inv), inv_rem(Inv, gold, B, NInv),
        world:update(W, A.put(inv, NInv).put(bounty, 0).put(fac, citizen), NW),
        Evts = [bounty_paid(Id, B)]
    ).

step_jailbreak(W, Id, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), world:node(W, RId, N), ( get_dict(props, N, Props) -> true ; Props = [] ), \+ member(prison, Props) ->
        NW = W, Evts = [not_in_prison(Id, RId)]
    ;
        room(A, RId), world:node(W, RId, N),
        stat(A, dex, Dex), stat(A, str, Str), stat(A, luk, Luk),
        skill_val(A, stealth, Lvl), random_between(1, 20, Roll),
        Score is Roll + max(Dex, Str) + floor(Lvl * 0.5) + floor(Luk * 0.5),
        ( Score >= 20, get_dict(exits, N, ExitsDict), dict_keys(ExitsDict, Exits), Exits \== [] ->
            random_member(Dir, Exits),
            get_dict(Dir, ExitsDict, NRId), entity:room(A, NRId, A1),
            world:update(W, A1, NW), Evts = [jailbreak_success(Id, NRId)]
        ;
            hp(A, Hp), NHp is max(1, Hp - 20),
            world:update(W, A.put(hp, NHp), NW), Evts = [jailbreak_failed(Id, 20)]
        )
    ).

step_bribe_guard(W, Id, GuardQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; room(A, RId), combat:resolve_target(W, Id, RId, GuardQuery, G), alive(G), get_dict(tag, G, guard) ->
        bounty(A, B),
        ( B =:= 0 ->
            NW = W, Evts = [no_bounty(Id)]
        ; B >= 2000 ->
            NW = W, Evts = [bounty_too_high_to_bribe(Id, B)]
        ; BribeAmt is floor(B * 1.5), inv(A, Inv), inv_rem(Inv, gold, BribeAmt, NInv) ->
            random_between(1, 100, Roll), stat(A, cha, Cha), stat(A, luk, Luk),
            ( Roll + Cha + floor(Luk * 0.5) >= 40 ->
                world:update(W, A.put(inv, NInv).put(bounty, 0).put(fac, citizen), W1),
                npc_life:mod_mem(W1, G.id, Id, talk, NW),
                Evts = [bribe_accepted(Id, G.id, BribeAmt)]
            ;
                NB is B + 500, world:update(W, A.put(inv, NInv).put(bounty, NB), NW),
                Evts = [bribe_rejected(Id, G.id)]
            )
        ; BribeAmt is floor(B * 1.5), NW = W, Evts = [insufficient_gold(Id, BribeAmt)]
        )
    ;
        NW = W, Evts = [guard_not_found(Id, GuardQuery)]
    ).
