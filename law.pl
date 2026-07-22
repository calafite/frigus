:- module(law, [step_pay_bounty/4, step_jailbreak/4, step_bribe_guard/5]).

:- use_module(library(random)).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(move).

step_pay_bounty(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    room(A, RId), world:node(W, RId, N),
    member(town_hall, N.props),
    bounty(A, B), B > 0,
    inv(A, Inv), inv_rem(Inv, gold, B, NInv),
    world:update(W, A.put(inv, NInv).put(bounty, 0).put(fac, citizen), NW),
    Evts = [bounty_paid(Id, B)].

step_jailbreak(W, Id, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    room(A, RId), world:node(W, RId, N),
    member(prison, N.props),
    stat(A, dex, Dex), stat(A, str, Str),
    skill_val(A, stealth, Lvl),
    random_between(1, 20, Roll),
    Score is Roll + max(Dex, Str) + floor(Lvl * 0.5),
    ( Score >= 20 ->
        dict_keys(N.exits, Exits), random_member(Dir, Exits),
        get_dict(Dir, N.exits, NRId),
        entity:room(A, NRId, A1),
        world:update(W, A1, NW),
        Evts = [jailbreak_success(Id, NRId)]
    ;
        hp(A, Hp), NHp is max(1, Hp - 20),
        world:update(W, A.put(hp, NHp), NW),
        Evts = [jailbreak_failed(Id, 20)]
    ).

step_bribe_guard(W, Id, GuardId, NW, Evts) :-
    world:entity(W, Id, A), alive(A), status:can_act(A),
    world:entity(W, GuardId, G), alive(G),
    room(A, RId), room(G, RId), G.tag == guard,
    bounty(A, B), B > 0, B < 2000,
    BribeAmt is floor(B * 1.5),
    inv(A, Inv), inv_rem(Inv, gold, BribeAmt, NInv),
    random_between(1, 100, Roll),
    stat(A, int, Int),
    ( Roll + Int >= 40 ->
        world:update(W, A.put(inv, NInv).put(bounty, 0).put(fac, citizen), W1),
        npc_life:mod_mem(W1, GuardId, Id, talk, NW),
        Evts = [bribe_accepted(Id, GuardId, BribeAmt)]
    ;
        NB is B + 500,
        world:update(W, A.put(inv, NInv).put(bounty, NB), NW),
        Evts = [bribe_rejected(Id, GuardId)]
    ).
