:- module(visibility, [
    can_see/3,
    can_see_target/3,
    revealed_exits/4,
    reveal_details/3,
    resolve_exit/5,
    step_search/4
]).

:- use_module(entity).
:- use_module(world).
:- use_module(library(random)).
:- use_module(library(lists)).

can_see(W, A, RId) :-
    world:node(W, RId, N),
    ( \+ member(dark, N.props) -> true
    ; member(campfire(_), N.props) -> true
    ; member(light_orb(_), N.props) -> true
    ; member(brazier_lit, N.props) -> true
    ; props(A, P), member(night_vision, P) -> true
    ; inv(A, Inv), member(stack{tag: lit_torch, qty: _}, Inv) -> true
    ; equip(A, Eq), get_dict(shield, Eq, lit_torch) -> true
    ).

can_see_target(W, A, T) :-
    room(A, R1), room(T, R2),
    ( R1 == R2 ->
        ( affs(T, Affs), member(aff{type: hidden, val: HidePower, dur: _}, Affs) ->
            stat(A, wis, Wis), stat(A, luk, Luk),
            random_between(1, 20, Roll),
            Roll + floor(Wis * 0.8) + floor(Luk * 0.2) >= HidePower
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
        stat(A, wis, Wis), stat(A, luk, Luk),
        get_dict(reqs, Node, Reqs),
        dict_keys(Secrets, SecKeys),
        findall(K, (member(K, SecKeys), get_dict(K, Reqs, ReqVal), Wis + floor(Luk * 0.3) >= ReqVal), FoundSecrets),
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
    stat(A, wis, Wis), stat(A, luk, Luk),
    Wis + floor(Luk * 0.3) >= ReqVal,
    get_dict(Dir, Secrets, NRId).

reveal_details(A, Node, FullDesc) :-
    ( \+ member(dark, Node.props) ; props(A, P), member(night_vision, P) ), !,
    Base = Node.desc,
    ( get_dict(details, Node, Details) ->
        stat(A, wis, Wis), stat(A, luk, Luk),
        EffInt is Wis + floor(Luk * 0.2),
        dict_pairs(Details, _, Pairs),
        findall(Txt, (
            member(K-Txt, Pairs),
            atom_number(K, ReqVal),
            EffInt >= ReqVal
        ), Extras),
        atomic_list_concat([Base | Extras], " ", FullDesc)
    ;
        FullDesc = Base
    ).
reveal_details(A, Node, FullDesc) :-
    get_dict(ambience, Node, Amb), !,
    get_dict(sound, Amb, Sound),
    get_dict(smell, Amb, Smell),
    atomic_list_concat(["It is dark. You hear ", Sound, " and smell ", Smell, "."], "", FullDesc).
reveal_details(_, _, "It is dark. You hear nothing.").

step_search(W, Id, W, Evts) :-
    world:entity(W, Id, A), room(A, RId),
    world:node(W, RId, N),
    ( get_dict(secrets, N, Secrets) ->
        stat(A, wis, Wis), stat(A, luk, Luk),
        get_dict(reqs, N, Reqs),
        dict_keys(Secrets, SecKeys),
        findall(Dir, (
            member(Dir, SecKeys),
            get_dict(Dir, Reqs, ReqVal),
            Wis + floor(Luk * 0.5) + 5 >= ReqVal
        ), Found),
        ( Found \== [] -> Evts = [searched(Id, RId, Found)] ; Evts = [searched_nothing(Id, RId)] )
    ;
        Evts = [searched_nothing(Id, RId)]
    ).
