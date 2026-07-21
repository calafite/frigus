:- module(visibility, [
    can_see/3,
    can_see_target/3,
    revealed_exits/4,
    reveal_details/3,
    resolve_exit/5
]).

:- use_module(entity).
:- use_module(world).
:- use_module(library(random)).
:- use_module(library(lists)).

can_see(W, A, RId) :-
    world:node(W, RId, N),
    ( \+ member(dark, N.props) -> true
    ; get_dict(props, A, P), member(night_vision, P) -> true
    ; inv(A, Inv), member(stack{tag: torch, qty: _}, Inv) -> true
    ; equip(A, Eq), get_dict(shield, Eq, torch) -> true
    ).

can_see_target(W, A, T) :-
    room(A, R1), room(T, R2),
    ( R1 == R2 ->
        ( affs(T, Affs), member(aff{type: hidden, val: HidePower, dur: _}, Affs) ->
            stat(A, int, Int),
            random_between(1, 20, Roll),
            Roll + Int >= HidePower
        ; true
        )
    ;
        world:node(W, R1, N1),
        resolve_exit(W, A, N1, _, R2),
        can_see(W, A, R1),
        can_see(W, A, R2)
    ).

revealed_exits(_W, A, Node, Exits) :-
    dict_keys(Node.exits, NormalExits),
    ( get_dict(secrets, Node, Secrets) ->
        stat(A, int, Int),
        get_dict(reqs, Node, Reqs),
        dict_keys(Secrets, SecKeys),
        findall(K, (member(K, SecKeys), get_dict(K, Reqs, ReqVal), Int >= ReqVal), FoundSecrets),
        append(NormalExits, FoundSecrets, Exits)
    ;
        Exits = NormalExits
    ).

resolve_exit(_W, A, Node, Dir, NRId) :-
    get_dict(Dir, Node.exits, NRId), !.
resolve_exit(_W, A, Node, Dir, NRId) :-
    get_dict(secrets, Node, Secrets),
    get_dict(reqs, Node, Reqs),
    get_dict(Dir, Reqs, ReqVal),
    stat(A, int, Int),
    Int >= ReqVal,
    get_dict(Dir, Secrets, NRId).

reveal_details(A, Node, FullDesc) :-
    Base = Node.desc,
    ( get_dict(details, Node, Details) ->
        stat(A, int, Int),
        dict_pairs(Details, _, Pairs),
        findall(Txt, (
            member(K-Txt, Pairs),
            atom_number(K, ReqVal),
            Int >= ReqVal
        ), Extras),
        atomic_list_concat([Base | Extras], " ", FullDesc)
    ;
        FullDesc = Base
    ).
