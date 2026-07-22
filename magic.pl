:- module(magic, [step_cast_utility/6]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(cfg_magic).
:- use_module(entity).
:- use_module(world).
:- use_module(status).
:- use_module(move).
:- use_module(zone).

step_cast_utility(W, Id, Sp, TId, NW, Evts) :-
    world:entity(W, Id, A), status:can_cast(A), cds(A, Cds), \+ get_dict(Sp, Cds, _),
    config:req(Sp, ReqStat, ReqVal), stat(A, ReqStat, Val), Val >= ReqVal,
    stealth:strip_stealth(A, CleanA), cost(Sp, Cost), mp(CleanA, Mp), Mp >= Cost,
    NMp is Mp - Cost, mp(CleanA, NMp, CastA),
    ( config:cooldown(Sp, CD) -> cds(CastA, Cds.put(Sp, CD), FinalA) ; FinalA = CastA ),
    cast_utility(Sp, W, Id, FinalA, TId, NW, CastEvts),
    Evts = [cast_utility(Id, Sp) | CastEvts].

cast_utility(blink, W, Id, A, _, NW, [teleported(Id, NRId)]) :-
    room(A, RId), world:node(W, RId, N),
    dict_keys(N.exits, Exits), Exits \= [],
    random_member(Dir, Exits), get_dict(Dir, N.exits, NRId),
    world:update(W, A.put(room, NRId).put(state, normal).put(climb_state, false), NW).

cast_utility(teleport, W, Id, A, DestId, NW, [teleported(Id, DestId)]) :-
    atom(DestId),
    get_dict(landmarks, A, Known), member(DestId, Known),
    world:update(W, A.put(room, DestId).put(state, normal).put(climb_state, false), NW).

cast_utility(invisibility, W, Id, A, _, NW, Evts) :-
    stat(A, int, Int), stat(A, wis, Wis),
    Power is floor(Int * 0.7) + floor(Wis * 0.3) + 10,
    status:apply_aff(A, aff{type: hidden, val: Power, dur: 10}, NA, Evts),
    world:update(W, NA, NW).

cast_utility(light_spell, W, Id, A, _, NW, Evts) :-
    room(A, RId), world:node(W, RId, N),
    ( member(dark, N.props) ->
        select(dark, N.props, Rest), NProps = [light_orb(30), originally_dark | Rest],
        Evts = [room_lit_magically(RId)]
    ;
        \+ member(light_orb(_), N.props), NProps = [light_orb(30) | N.props],
        Evts = [room_illuminated_magically(RId)]
    ),
    NN = N.put(props, NProps),
    world:update(W, A, W1), zone:update_room(W1, NN, NW).

cast_utility(dispel, W, Id, A, TId, NW, [dispelled(Id, TId)]) :-
    world:entity(W, TId, T), alive(T), room(A, RId), room(T, RId),
    affs(T, Affs),
    findall(aff{type: Type, val: V, dur: D}, (
        member(aff{type: Type, val: V, dur: D}, Affs),
        \+ member(Type, [plague, fever, blight, poison, burn, bleed, bloodline_curse, stun, freeze])
    ), PosAffs),
    world:update(W, A, W1),
    world:update(W1, T.put(affs, PosAffs), NW).

cast_utility(identify_spell, W, Id, A, ItemId, NW, [identified(Id, ItemId, NItem.name)]) :-
    atom(ItemId), inv(A, Inv),
    select(Item, Inv, Inv1), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props), member(unidentified, Props),
    select(unidentified, Props, RestProps),
    NItem = Item.put(props, RestProps),
    world:update(W, A.put(inv, [NItem|Inv1]), NW).

cast_utility(remove_curse, W, Id, A, ItemId, NW, [uncursed(Id, ItemId, NItem.name)]) :-
    atom(ItemId), inv(A, Inv),
    select(Item, Inv, Inv1), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props), member(cursed, Props),
    select(cursed, Props, RestProps),
    NItem = Item.put(props, RestProps),
    world:update(W, A.put(inv, [NItem|Inv1]), NW).

cast_utility(remove_curse, W, Id, A, ItemId, NW, [uncursed(Id, ItemId, NItem.name)]) :-
    atom(ItemId), equip(A, Eq), dict_pairs(Eq, _, Pairs),
    member(Slot-Item, Pairs), is_dict(Item, item), Item.id == ItemId,
    get_dict(props, Item, Props), member(cursed, Props), !,
    select(cursed, Props, RestProps),
    NItem = Item.put(props, RestProps),
    NEq = Eq.put(Slot, NItem),
    world:update(W, A.put(equip, NEq), NW).

cast_utility(banish, W, Id, A, TId, NW, [banished(TId, VoidId)]) :-
    world:entity(W, TId, T), alive(T), room(A, RId), room(T, RId),
    stat(A, int, Int), stat(A, wis, Wis),
    stat(T, int, TInt), stat(T, wis, TWis), stat(T, con, TCon),
    random_between(1, 20, Roll),
    Score is Roll + floor(Int * 0.5) + floor(Wis * 0.5),
    Target is 10 + floor(TInt * 0.3) + floor(TWis * 0.3) + floor(TCon * 0.4),
    ( Score >= Target ->
        ritual:ensure_void_prison(W, W1),
        VoidId = void_prison,
        world:update(W1, T.put(room, VoidId).put(state, normal).put(climb_state, false), NW)
    ;
        NW = W
    ).

cast_utility(planar_gate, W, Id, A, _, NW, [rift_opened(RId, void_prison)]) :-
    room(A, RId), world:node(W, RId, N),
    ritual:ensure_void_prison(W, W1),
    NN = N.put(exits, N.exits.put(rift, void_prison)),
    zone:update_room(W1, NN, NW).

cast_utility(gender_shift, W, Id, A, TId, NW, [gender_swapped(TId, Old, New)]) :-
    world:entity(W, TId, T), alive(T),
    room(A, RId), room(T, RId),
    gender(T, Old),
    ( Old == male -> New = female ; New = male ),
    world:update(W, T.put(gender, New), NW).

cast_utility(curse_word, W, Id, A, Word, NW, [word_cursed(Id, Word)]) :-
    atom(Word),
    world:flags(W, Fs),
    ( get_dict(cursed_words, Fs, CursedDict) ->
        NCursed = CursedDict.put(Word, Id)
    ;
        NCursed = dict{}.put(Word, Id)
    ),
    NFs = Fs.put(cursed_words, NCursed),
    world:flags(W, NFs, W1),
    world:update(W1, A, NW).
