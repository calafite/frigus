:- module(prog, [add_xp/4, step_train/5, rebirth_player/3]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

add_xp(A, Amt, NA, Evts) :-
    xp(A, Cur),
    NXp is Cur + Amt,
    lvl_check(A, NXp, NA, Evts).

lvl_check(A, Xp, NA, [lvl_up(A.id, NLvl) | REvts]) :-
    lvl(A, Lvl),
    Req is Lvl * Lvl * 100,
    Xp >= Req, !,
    NXp is Xp - Req,
    NLvl is Lvl + 1,
    class(A, C),
    config:growth(C, str, GS), config:growth(C, dex, GD), config:growth(C, int, GI),
    get_ceil(A, str, CS), str(A, Str), NStr is min(CS, Str + GS),
    get_ceil(A, dex, CD), dex(A, Dex), NDex is min(CD, Dex + GD),
    get_ceil(A, int, CI), int(A, Int), NInt is min(CI, Int + GI),
    A1 = A.put(lvl, NLvl).put(str, NStr).put(dex, NDex).put(int, NInt),
    lvl_check(A1, NXp, NA, REvts).
lvl_check(A, Xp, NA, []) :-
    xp(A, Xp, NA).

step_train(W, Id, Stat, NW, Evts) :-
    world:entity(W, Id, A),
    alive(A),
    status:can_act(A),
    stat(A, Stat, Val),
    Cost is Val * 20,
    xp(A, Xp), Xp >= Cost,
    NXp is Xp - Cost,
    get_ceil(A, Stat, Ceil),
    ( Val < Ceil ->
        NVal is Val + 1,
        A1 = A.put(xp, NXp).put(Stat, NVal),
        Evts = [trained(Id, Stat, NVal)],
        world:update(W, A1, NW)
    ;
        random_between(1, 100, Roll),
        ( Roll <= 5 ->
            NCeil is Ceil + 1,
            NVal is Val + 1,
            ceils(A, Ceils),
            NCeils = Ceils.put(Stat, NCeil),
            A1 = A.put(xp, NXp).put(Stat, NVal).put(ceils, NCeils),
            Evts = [breakthrough(Id, Stat, NCeil, NVal)],
            world:update(W, A1, NW)
        ;
            A1 = A.put(xp, NXp),
            Evts = [train_failed(Id, Stat)],
            world:update(W, A1, NW)
        )
    ).

keep_stack(S) :-
    get_dict(tag, S, Tag),
    ( config:soulbound(Tag) -> true
    ; get_dict(enchanted, S, Enc), member(permanent, E) -> true
    ).

rebirth_player(P, NP, SpawnRId) :-
    SpawnRId = temple,
    get_dict(max_hp, P, MaxHp),
    get_dict(max_mp, P, MaxMp),
    ( is_special(P) ->
        NP = P.put(hp, MaxHp).put(mp, MaxMp).put(room, SpawnRId).put(affs, []).put(cds, cds{})
    ;
        inv(P, Inv),
        include(keep_stack, Inv, NInv),
        str(P, Str), NStr is max(10, floor(Str * 0.8)),
        dex(P, Dex), NDex is max(10, floor(Dex * 0.8)),
        int(P, Int), NInt is max(10, floor(Int * 0.8)),
        NP = P.put(hp, MaxHp)
               .put(mp, MaxMp)
               .put(lvl, 1)
               .put(xp, 0)
               .put(str, NStr)
               .put(dex, NDex)
               .put(int, NInt)
               .put(inv, NInv)
               .put(room, SpawnRId)
               .put(equip, equip{wpn: fists, shield: none, body: none})
               .put(affs, [])
               .put(cds, cds{})
    ).
