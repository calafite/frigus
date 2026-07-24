:- module(entity, [
    is_alive/1,
    get_stat/3,
    mod_hp/3,
    has_item/2,
    add_item/4,
    rem_item/4,
    add_threat/4,
    rem_threat/3,
    add_bounty/3,
    clear_bounty/2,
    mark_combat/2,
    has_trait/2,
    check_pass/2,
    check_admin/1,
    has_aff/2,
    get_aff/3,
    apply_aff/5,
    remove_aff/3
]).

:- use_module(library(lists)).
:- use_module('../config/spawn').

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

is_alive(Ent) :-
    is_dict(Ent),
    get_dict(hp, Ent, Hp),
    Hp > 0.

get_stat(Ent, Stat, Total) :-
    is_dict(Ent), !,
    ( get_dict(Stat, Ent, Base) -> true ; Base = 10 ),
    ( get_dict(race, Ent, RawRace) ->
        to_atom(RawRace, Race),
        findall(B, spawn_config:race_bonus(Race, Stat, B), BList),
        sum_list(BList, Bonus)
    ;
        Bonus = 0
    ),
    Total is Base + Bonus.
get_stat(_, _, 10).

has_trait(Ent, Trait) :-
    is_dict(Ent),
    get_dict(race, Ent, RawRace),
    to_atom(RawRace, Race),
    spawn_config:race_trait(Race, Trait).

check_pass(Ent, Pass) :-
    is_dict(Ent),
    ( get_dict(pass, Ent, CurPass) -> CurPass == Pass ; true ).

check_admin(Ent) :-
    is_dict(Ent),
    get_dict(admin, Ent, true).

mod_hp(Ent, Delta, NEnt) :-
    get_dict(hp, Ent, Hp),
    ( get_dict(max_hp, Ent, Max) -> true ; Max = 50 ),
    NHp is max(0, min(Max, Hp + Delta)),
    NEnt = Ent.put(hp, NHp).

has_item(Ent, Tag) :-
    is_dict(Ent),
    get_dict(inv, Ent, Inv),
    member(Stack, Inv),
    is_dict(Stack),
    get_dict(tag, Stack, Tag),
    get_dict(qty, Stack, Qty),
    Qty >= 1, !.

add_item(Ent, Tag, Qty, NEnt) :-
    ( is_dict(Ent), get_dict(inv, Ent, Inv) -> true ; Inv = [] ),
    add_to_inv(Inv, Tag, Qty, NInv),
    NEnt = Ent.put(inv, NInv).

add_to_inv([], Tag, Qty, [stack{tag: Tag, qty: Qty}]).
add_to_inv([Stack|Rest], Tag, Qty, [NStack|Rest]) :-
    is_dict(Stack),
    get_dict(tag, Stack, Tag), !,
    get_dict(qty, Stack, Cur),
    NewQ is Cur + Qty,
    NStack = Stack.put(qty, NewQ).
add_to_inv([Item|Rest], Tag, Qty, [Item|NRest]) :-
    add_to_inv(Rest, Tag, Qty, NRest).

rem_item(Ent, Tag, Qty, NEnt) :-
    ( is_dict(Ent), get_dict(inv, Ent, Inv) -> true ; Inv = [] ),
    rem_from_inv(Inv, Tag, Qty, NInv),
    NEnt = Ent.put(inv, NInv).

rem_from_inv([], _, _, []) :- !.
rem_from_inv([Stack|Rest], Tag, Qty, NInv) :-
    is_dict(Stack),
    get_dict(tag, Stack, Tag),
    get_dict(qty, Stack, Cur),
    Cur >= Qty, !,
    NewQ is Cur - Qty,
    ( NewQ =:= 0 -> NInv = Rest ; NStack = Stack.put(qty, NewQ), NInv = [NStack|Rest] ).
rem_from_inv([Item|Rest], Tag, Qty, [Item|NRest]) :-
    rem_from_inv(Rest, Tag, Qty, NRest).

add_threat(Ent, TgtId, Val, NEnt) :-
    is_dict(Ent),
    ( get_dict(threats, Ent, Th) -> true ; Th = dict{} ),
    ( get_dict(TgtId, Th, CurVal) -> NVal is CurVal + Val ; NVal = Val ),
    NTh = Th.put(TgtId, NVal),
    NEnt = Ent.put(threats, NTh), !.
add_threat(Ent, _, _, Ent).

rem_threat(Ent, TgtId, NEnt) :-
    is_dict(Ent),
    ( get_dict(threats, Ent, Th) ->
        ( del_dict(TgtId, Th, _, NTh) -> NEnt = Ent.put(threats, NTh) ; NEnt = Ent )
    ; NEnt = Ent ).

add_bounty(Ent, Val, NEnt) :-
    is_dict(Ent),
    ( get_dict(bounty, Ent, Cur) -> true ; Cur = 0 ),
    New is Cur + Val,
    NEnt = Ent.put(bounty, New).

clear_bounty(Ent, NEnt) :-
    is_dict(Ent),
    NEnt = Ent.put(bounty, 0).

mark_combat(Ent, NEnt) :-
    is_dict(Ent),
    ( get_dict(cds, Ent, Cds) -> true ; Cds = dict{} ),
    NCds = Cds.put(combat, 3),
    NEnt = Ent.put(cds, NCds).

% ==========================================
% STATUS EFFECTS (AFFLICTIONS & BUFFS) API
% ==========================================

% Check if entity currently has a specific affliction
has_aff(Ent, AffTag) :-
    is_dict(Ent),
    get_dict(affs, Ent, Affs),
    get_dict(AffTag, Affs, _).

% Retrieve affliction details (Duration and Magnitude)
get_aff(Ent, AffTag, dict{dur: Dur, mag: Mag}) :-
    is_dict(Ent),
    get_dict(affs, Ent, Affs),
    get_dict(AffTag, Affs, AffNode),
    get_dict(dur, AffNode, Dur),
    get_dict(mag, AffNode, Mag).

% Apply or refresh an affliction on an entity
apply_aff(Ent, AffTag, Dur, Mag, NEnt) :-
    is_dict(Ent),
    ( get_dict(affs, Ent, Affs) -> true ; Affs = dict{} ),
    ( get_dict(AffTag, Affs, CurAff) ->
        get_dict(dur, CurAff, CurDur),
        NDur is max(CurDur, Dur),
        NAffNode = dict{dur: NDur, mag: Mag}
    ;
        NAffNode = dict{dur: Dur, mag: Mag}
    ),
    NAffs = Affs.put(AffTag, NAffNode),
    NEnt = Ent.put(affs, NAffs).

% Forcefully remove an affliction
remove_aff(Ent, AffTag, NEnt) :-
    is_dict(Ent),
    ( get_dict(affs, Ent, Affs) ->
        ( del_dict(AffTag, Affs, _, NAffs) -> NEnt = Ent.put(affs, NAffs) ; NEnt = Ent )
    ; NEnt = Ent ).
