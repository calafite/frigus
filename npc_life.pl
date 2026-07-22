:- module(npc_life, [step_life/4, mod_mem/5, get_mem/3]).

:- use_module(library(random)).
:- use_module(entity).
:- use_module(world).
:- use_module(cfg_npc).
:- use_module(ai_path).
:- use_module(move).
:- use_module(survival).
:- use_module(config).

mod_mem(W, NpcId, PlyrId, Type, NW) :-
    world:entity(W, NpcId, M),
    mems(M, Mems),
    cfg_npc:mem_mod(Type, Val),
    ( get_dict(PlyrId, Mems, Cur) -> NVal is Cur + Val ; NVal = Val ),
    world:update(W, M.put(mems, Mems.put(PlyrId, NVal)), NW).

get_mem(M, PlyrId, Val) :-
    mems(M, Mems), get_dict(PlyrId, Mems, Val), !.
get_mem(_, _, 0).

step_life(W, Id, NW, Evts) :-
    world:entity(W, Id, M),
    job(M, JobTag), JobTag \== none,
    get_dict(env, W, Env), Hr = Env.hr,
    ( cfg_npc:base_job(JobTag, BaseJob) -> true ; BaseJob = JobTag ),
    cfg_npc:job_sched(BaseJob, Hr, ExpState),
    act_state(M, CurState),
    ( CurState == ExpState ->
        exec_state(ExpState, W, Id, M, NW, Evts)
    ;
        trans_state(CurState, ExpState, W, Id, M, NW, Evts)
    ).
step_life(W, _, W, []).

trans_state(sleep, ExpState, W, Id, M, NW, Evts) :-
    survival:step_wake(W, Id, W1, Evts1),
    world:entity(W1, Id, M1),
    M2 = M1.put(act_state, ExpState),
    world:update(W1, M2, NW),
    Evts = Evts1.
trans_state(_, ExpState, W, Id, M, NW, []) :-
    world:update(W, M.put(act_state, ExpState), NW).

exec_state(sleep, W, Id, M, NW, Evts) :-
    home(M, HId), HId \== none,
    room(M, RId),
    ( RId == HId ->
        get_dict(state, M, S),
        ( S \== sleeping -> survival:step_sleep(W, Id, NW, Evts) ; NW = W, Evts = [] )
    ;
        ai_path:step_towards(W, Id, HId, NW, Evts)
    ).

exec_state(eat, W, Id, M, NW, Evts) :-
    inv(M, Inv), member(stack{tag: bread, qty: _}, Inv), !,
    item:step_use(W, Id, bread, NW, Evts).
exec_state(eat, W, Id, M, NW, Evts) :-
    inv(M, Inv), member(stack{tag: apple, qty: _}, Inv), !,
    item:step_use(W, Id, apple, NW, Evts).
exec_state(eat, W, Id, M, NW, Evts) :-
    room(M, RId), world:node(W, RId, N),
    ( member(tavern, N.props) ->
        NW = W, Evts = []
    ;
        find_loc(W, RId, tavern, TgtId), TgtId \== none ->
        ai_path:step_towards(W, Id, TgtId, NW, Evts)
    ;
        NW = W, Evts = []
    ).

exec_state(work, W, Id, M, NW, Evts) :-
    work(M, WId), WId \== none,
    room(M, RId),
    ( RId == WId ->
        do_job_action(M, W, NW, Evts)
    ;
        ai_path:step_towards(W, Id, WId, NW, Evts)
    ).

do_job_action(M, W, NW, Evts) :-
    M.tag == miner, random_between(1, 100, R), R =< 20, !,
    inv(M, Inv), inv_add(Inv, iron_ore, 1, NInv),
    world:update(W, M.put(inv, NInv), NW), Evts = [mined_ore(M.id)].
do_job_action(M, W, NW, Evts) :-
    M.tag == peasant, random_between(1, 100, R), R =< 20, !,
    inv(M, Inv), inv_add(Inv, wheat, 1, NInv),
    world:update(W, M.put(inv, NInv), NW), Evts = [harvested_crop(M.id)].
do_job_action(M, W, NW, Evts) :-
    M.tag == scholar, random_between(1, 100, R), R =< 10, !,
    inv(M, Inv), inv_add(Inv, tome, 1, NInv),
    world:update(W, M.put(inv, NInv), NW), Evts = [scribed_tome(M.id)].
do_job_action(_, W, W, []).

exec_state(leisure, W, Id, M, NW, Evts) :-
    room(M, RId), world:node(W, RId, N),
    ( member(square, N.props) ->
        ( npc_trade(W, M, RId, NW, Evts) -> true
        ; random_between(1, 100, R),
          ( R =< 20 -> dict_keys(N.exits, Exits), random_member(Dir, Exits), move:step_move(W, Id, Dir, NW, Evts)
          ; NW = W, Evts = [] ) )
    ;
        find_loc(W, RId, square, TgtId), TgtId \== none ->
        ai_path:step_towards(W, Id, TgtId, NW, Evts)
    ;
        NW = W, Evts = []
    ).

exec_state(_, W, _, _, W, []).

npc_trade(W, M, RId, NW, Evts) :-
    world:room_entities(W, RId, Ents),
    member(T, Ents), is_dict(T, mob), T.id \== M.id,
    act_state(T, leisure),
    inv(M, MInv), member(stack{tag: gold, qty: G}, MInv), G >= 10,
    inv(T, TInv), member(stack{tag: Item, qty: Q}, TInv), Q > 0, Item \== gold,
    config:consumable(Item, _),
    inv_rem(MInv, gold, 10, MInv1), inv_add(MInv1, Item, 1, MInv2),
    inv_rem(TInv, Item, 1, TInv1), inv_add(TInv1, gold, 10, TInv2),
    world:update(W, M.put(inv, MInv2), W1),
    world:update(W1, T.put(inv, TInv2), NW),
    Evts = [npc_trade(M.id, T.id, Item, 10)].

find_loc(W, Start, Prop, TgtId) :-
    findall(R.id, (member(R, W.rooms), member(Prop, R.props)), Cands),
    Cands \= [],
    ai_path:find_path(W, Start, TgtId, 20, _),
    member(TgtId, Cands), !.
find_loc(_, _, _, none).
