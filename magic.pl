:- module(magic, [step_cast_utility/6]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(cfg_magic).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(move).
:- use_module(zone).
:- use_module(ritual).

step_cast_utility(W, Id, Sp, TId, NW, Evts) :-
    world:entity(W, Id, A),
    ( cast_utility(Sp, W, Id, A, TId, NW, CastEvts) ->
        Evts = [cast_utility(Id, Sp) | CastEvts]
    ;
        NW = W, Evts = [cast_utility_failed(Id, Sp)]
    ).

cast_utility(blink, W, Id, A, _, NW, [teleported(Id, NRId)]) :-
    room(A, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [],
    random_member(Dir, Exits), get_dict(Dir, N.exits, NRId),
    world:update(W, A.put(room, NRId).put(state, normal).put(climb_state, false), NW), !.

cast_utility(teleport, W, Id, A, DestId, NW, [teleported(Id, DestId)]) :-
    atom(DestId),
    get_dict(landmarks, A, Known), member(DestId, Known),
    world:update(W, A.put(room, DestId).put(state, normal).put(climb_state, false), NW), !.

cast_utility(invisibility, W, _Id, A, _, NW, Evts) :-
    stat(A, int, Int), stat(A, wis, Wis),
    Power is floor(Int * 0.7) + floor(Wis * 0.3) + 10,
    status:apply_aff(A, aff{type: hidden, val: Power, dur: 10}, NA, Evts),
    world:update(W, NA, NW), !.

cast_utility(light_spell, W, _Id, A, _, NW, Evts) :-
    room(A, RId), world:node(W, RId, N),
    ( member(dark, N.props) ->
        select(dark, N.props, Rest), NProps = [light_orb(30), originally_dark | Rest],
        Evts = [room_lit_magically(RId)]
    ;
        \+ member(light_orb(_), N.props), NProps = [light_orb(30) | N.props],
        Evts = [room_illuminated_magically(RId)]
    ),
    NN = N.put(props, NProps),
    world:update(W, A, W1), zone:update_room(W1, NN, NW), !.

cast_utility(dispel, W, Id, A, TId, NW, [dispelled(Id, Target.id)]) :-
    room(A, RId), combat:resolve_target(W, Id, RId, TId, Target), alive(Target),
    affs(Target, Affs),
    findall(aff{type: Type, val: V, dur: D}, (
        member(aff{type: Type, val: V, dur: D}, Affs),
        \+ member(Type, [plague, fever, blight, poison, burn, bleed, bloodline_curse, stun, freeze])
    ), PosAffs),
    world:update(W, A, W1),
    world:update(W1, Target.put(affs, PosAffs), NW), !.

cast_utility(identify_spell, W, Id, A, ItemId, NW, [identified(Id, TargetItemId, NItem.name)]) :-
    inv(A, Inv),
    select(Item, Inv, Inv1), is_dict(Item, item),
    ( Item.id == ItemId ; Item.tag == ItemId ; (get_dict(name, Item, Name), string_lower(Name, LName), string_lower(ItemId, LItemId), sub_string(LName, _, _, _, LItemId)) ),
    get_dict(props, Item, Props), member(unidentified, Props),
    select(unidentified, Props, RestProps),
    TargetItemId = Item.id,
    NItem = Item.put(props, RestProps),
    world:update(W, A.put(inv, [NItem|Inv1]), NW), !.

cast_utility(remove_curse, W, Id, A, ItemId, NW, [uncursed(Id, TargetItemId, NItem.name)]) :-
    inv(A, Inv),
    select(Item, Inv, Inv1), is_dict(Item, item),
    ( Item.id == ItemId ; Item.tag == ItemId ; (get_dict(name, Item, Name), string_lower(Name, LName), string_lower(ItemId, LItemId), sub_string(LName, _, _, _, LItemId)) ),
    get_dict(props, Item, Props), member(cursed, Props),
    select(cursed, Props, RestProps),
    TargetItemId = Item.id,
    NItem = Item.put(props, RestProps),
    world:update(W, A.put(inv, [NItem|Inv1]), NW), !.

cast_utility(remove_curse, W, Id, A, ItemId, NW, [uncursed(Id, TargetItemId, NItem.name)]) :-
    equip(A, Eq), dict_pairs(Eq, _, Pairs),
    member(Slot-Item, Pairs), is_dict(Item, item),
    ( Item.id == ItemId ; Item.tag == ItemId ; (get_dict(name, Item, Name), string_lower(Name, LName), string_lower(ItemId, LItemId), sub_string(LName, _, _, _, LItemId)) ),
    get_dict(props, Item, Props), member(cursed, Props), !,
    select(cursed, Props, RestProps),
    TargetItemId = Item.id,
    NItem = Item.put(props, RestProps),
    NEq = Eq.put(Slot, NItem),
    world:update(W, A.put(equip, NEq), NW), !.

cast_utility(banish, W, Id, A, TId, NW, [banished(Target.id, VoidId)]) :-
    room(A, RId), combat:resolve_target(W, Id, RId, TId, Target), alive(Target),
    stat(A, int, Int), stat(A, wis, Wis),
    stat(Target, int, TInt), stat(Target, wis, TWis), stat(Target, con, TCon),
    random_between(1, 20, Roll),
    Score is Roll + floor(Int * 0.5) + floor(Wis * 0.5),
    ReqTarget is 10 + floor(TInt * 0.3) + floor(TWis * 0.3) + floor(TCon * 0.4),
    ( Score >= ReqTarget ->
        ritual:ensure_void_prison(W, W1),
        VoidId = void_prison,
        world:update(W1, Target.put(room, VoidId).put(state, normal).put(climb_state, false), NW)
    ;
        NW = W
    ), !.

cast_utility(planar_gate, W, _Id, A, _, NW, [rift_opened(RId, void_prison)]) :-
    room(A, RId), world:node(W, RId, N),
    ritual:ensure_void_prison(W, W1),
    NN = N.put(exits, N.exits.put(rift, void_prison)),
    zone:update_room(W1, NN, NW), !.

cast_utility(gender_shift, W, Id, A, TId, NW, [gender_swapped(Target.id, Old, New)]) :-
    room(A, RId), combat:resolve_target(W, Id, RId, TId, Target), alive(Target),
    gender(Target, Old),
    ( Old == male -> New = female ; New = male ),
    world:update(W, Target.put(gender, New), NW), !.

cast_utility(Sp, W, Id, _A, _TId, W, [cast_utility_failed(Id, Sp)]).
