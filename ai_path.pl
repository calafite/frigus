:- module(ai_path, [find_path/5, step_towards/5]).

:- use_module(world).
:- use_module(move).

bfs(_, _, [[End|Path]|_], End, _, [End|Path]) :- !.
bfs(W, ExitsFn, [[Cur|Path]|Queue], End, Visited, Final) :-
    findall([Next,Cur|Path], (
        call(ExitsFn, W, Cur, Nexts),
        member(Next, Nexts),
        \+ member(Next, Visited)
    ), NewPaths),
    findall(N, member([N|_], NewPaths), NewNodes),
    append(Visited, NewNodes, NVisited),
    append(Queue, NewPaths, NQueue),
    bfs(W, ExitsFn, NQueue, End, NVisited, Final).
bfs(_, _, [], _, _, []) :- !.

room_exits(W, RId, Nexts) :-
    world:node(W, RId, N),
    dict_pairs(N.exits, _, Pairs),
    findall(Tgt, member(_-Tgt, Pairs), Nexts).

find_path(W, Start, End, Limit, Route) :-
    bfs(W, ai_path:room_exits, [[Start]], End, [Start], RRoute),
    reverse(RRoute, Route),
    length(Route, L),
    L =< Limit, !.
find_path(_, _, _, _, []).

step_towards(W, Id, TgtId, NW, Evts) :-
    world:entity(W, Id, M), room(M, Cur),
    find_path(W, Cur, TgtId, 15, Route),
    ( Route = [Cur, Next|_] ->
        world:node(W, Cur, N), dict_pairs(N.exits, _, Pairs),
        ( member(Dir-Next, Pairs) ->
            move:step_move(W, Id, Dir, NW, Evts)
        ; NW = W, Evts = [] )
    ; NW = W, Evts = [] ).
