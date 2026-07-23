:- module(trade, [step_trade/5]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(social).
:- use_module(combat).

get_role(Id, Tr, p1) :- get_dict(p1, Tr, P1), P1 == Id, !.
get_role(Id, Tr, p2) :- get_dict(p2, Tr, P2), P2 == Id, !.

get_trades(W, S, Trades) :-
    social:soc(W, S),
    ( get_dict(trades, S, Trades) -> true ; Trades = dict{} ).

mod_tr(W, TId, Tr, NW) :-
    get_trades(W, S, Trades),
    NTrades = Trades.put(TId, Tr),
    social:soc(W, S.put(trades, NTrades), NW).

step_trade(W, Id, req(TgtQuery), NW, Evts) :-
    world:entity(W, Id, A), room(A, RId),
    ( combat:resolve_target(W, Id, RId, TgtQuery, T), T.id \== Id ->
        random_between(10000, 99999, R), atomic_list_concat([trade_, R], TId),
        Tr = dict{p1: Id, p2: T.id, i1: [], i2: [], g1: 0, g2: 0, r1: false, r2: false},
        mod_tr(W, TId, Tr, NW),
        Evts = [trade_req(Id, T.id, TId)]
    ;
        NW = W, Evts = [cannot_trade(Id, TgtQuery)]
    ).

step_trade(W, Id, accept(TId), NW, Evts) :-
    get_trades(W, S, Trades),
    ( get_dict(TId, Trades, Tr), get_dict(p2, Tr, P2), P2 == Id ->
        NW = W, Evts = [trade_accepted(TId)]
    ;
        NW = W, Evts = [trade_not_found(Id, TId)]
    ).

step_trade(W, Id, add(TId, Tag, Q), NW, Evts) :-
    get_trades(W, S, Trades),
    ( get_dict(TId, Trades, Tr), get_role(Id, Tr, R),
      world:entity(W, Id, A), inv(A, Inv), inv_rem(Inv, Tag, Q, NInv)
    ->
        ( R == p1 -> inv_add(Tr.i1, Tag, Q, NI), NTr = Tr.put(i1, NI)
        ; inv_add(Tr.i2, Tag, Q, NI), NTr = Tr.put(i2, NI) ),
        world:update(W, A.put(inv, NInv), W1),
        mod_tr(W1, TId, NTr.put(r1, false).put(r2, false), NW),
        Evts = [trade_updated(TId)]
    ;
        NW = W, Evts = [cannot_add_trade_item(Id, Tag)]
    ).

step_trade(W, Id, gold(TId, Amt), NW, Evts) :-
    get_trades(W, S, Trades),
    ( get_dict(TId, Trades, Tr), get_role(Id, Tr, R),
      world:entity(W, Id, A), inv(A, Inv), inv_rem(Inv, gold, Amt, NInv)
    ->
        ( R == p1 -> NG is Tr.g1 + Amt, NTr = Tr.put(g1, NG)
        ; NG is Tr.g2 + Amt, NTr = Tr.put(g2, NG) ),
        world:update(W, A.put(inv, NInv), W1),
        mod_tr(W1, TId, NTr.put(r1, false).put(r2, false), NW),
        Evts = [trade_updated(TId)]
    ;
        NW = W, Evts = [cannot_add_trade_gold(Id, Amt)]
    ).

step_trade(W, Id, ready(TId), NW, Evts) :-
    get_trades(W, S, Trades),
    ( get_dict(TId, Trades, Tr), get_role(Id, Tr, R) ->
        ( R == p1 -> NTr = Tr.put(r1, true) ; NTr = Tr.put(r2, true) ),
        ( NTr.r1 == true, NTr.r2 == true -> finish_trade(W, TId, NTr, NW, Evts)
        ; mod_tr(W, TId, NTr, NW), Evts = [trade_ready(Id, TId)] )
    ;
        NW = W, Evts = [trade_not_found(Id, TId)]
    ).

step_trade(W, Id, cancel(TId), NW, Evts) :-
    get_trades(W, S, Trades),
    ( get_dict(TId, Trades, Tr), get_role(Id, Tr, _) ->
        world:entity(W, Tr.p1, P1), world:entity(W, Tr.p2, P2),
        refund(P1, Tr.i1, Tr.g1, NP1), refund(P2, Tr.i2, Tr.g2, NP2),
        del_dict(TId, Trades, _, NTrades), social:soc(W, S.put(trades, NTrades), W1),
        world:update(W1, NP1, W2), world:update(W2, NP2, NW),
        Evts = [trade_canceled(TId)]
    ;
        NW = W, Evts = [trade_not_found(Id, TId)]
    ).

refund(P, Is, G, NP) :-
    inv(P, Inv), merge_inv(Inv, Is, TInv),
    ( G > 0 -> inv_add(TInv, gold, G, NInv) ; NInv = TInv ),
    NP = P.put(inv, NInv).

merge_inv(Inv, [], Inv).
merge_inv(Inv, [stack{tag: T, qty: Q}|Ts], Out) :-
    inv_add(Inv, T, Q, Tmp), merge_inv(Tmp, Ts, Out).

finish_trade(W, TId, Tr, NW, [trade_finished(TId)]) :-
    world:entity(W, Tr.p1, P1), world:entity(W, Tr.p2, P2),
    refund(P1, Tr.i2, Tr.g2, NP1), refund(P2, Tr.i1, Tr.g1, NP2),
    get_trades(W, S, Trades),
    del_dict(TId, Trades, _, NTrades),
    social:soc(W, S.put(trades, NTrades), W1),
    world:update(W1, NP1, W2), world:update(W2, NP2, NW).
