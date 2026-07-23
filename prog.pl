:- module(prog, [add_xp/4, step_train/5, rebirth_player/3]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(config).
:- use_module(entity).
:- use_module(world).
:- use_module(status).

valid_stat(str).
valid_stat(dex).
valid_stat(con).
valid_stat(int).
valid_stat(wis).
valid_stat(cha).
valid_stat(luk).

growth_val(C, Stat, G) :- config:growth(C, Stat, G), !.
growth_val(_, _, 1).

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
    ( class(A, C) -> true ; C = fighter ),
    growth_val(C, str, GS), growth_val(C, dex, GD), growth_val(C, con, GC),
    growth_val(C, int, GI), growth_val(C, wis, GW), growth_val(C, cha, GCh),
    growth_val(C, luk, GL),
    get_ceil(A, str, CS), str(A, Str), NStr is min(CS, Str + GS),
    get_ceil(A, dex, CD), dex(A, Dex), NDex is min(CD, Dex + GD),
    get_ceil(A, con, CC), con(A, Con), NCon is min(CC, Con + GC),
    get_ceil(A, int, CI), int(A, Int), NInt is min(CI, Int + GI),
    get_ceil(A, wis, CW), wis(A, Wis), NWis is min(CW, Wis + GW),
    get_ceil(A, cha, CCh), cha(A, Cha), NCha is min(CCh, Cha + GCh),
    get_ceil(A, luk, CL), luk(A, Luk), NLuk is min(CL, Luk + GL),
    A1 = A.put(lvl, NLvl).put(str, NStr).put(dex, NDex).put(con, NCon)
          .put(int, NInt).put(wis, NWis).put(cha, NCha).put(luk, NLuk),
    lvl_check(A1, NXp, NA, REvts).
lvl_check(A, Xp, NA, []) :-
    xp(A, Xp, NA).

step_train(W, Id, StatQuery, NW, Evts) :-
    world:entity(W, Id, A),
    ( atom_string(Stat, StatQuery) -> true ; Stat = StatQuery ),
    ( \+ status:can_act(A) ->
        NW = W, Evts = [cannot_act(Id)]
    ; \+ valid_stat(Stat) ->
        NW = W, Evts = [invalid_stat(Id, StatQuery)]
    ;
        stat(A, Stat, Val), Cost is Val * 20,
        xp(A, Xp),
        ( Xp < Cost ->
            NW = W, Evts = [insufficient_xp(Id, Cost, Xp)]
        ;
            NXp is Xp - Cost,
            get_ceil(A, Stat, Ceil),
            ( Val < Ceil ->
                NVal is Val + 1,
                A1 = A.put(xp, NXp).put(Stat, NVal),
                world:update(W, A1, NW),
                Evts = [trained(Id, Stat, NVal)]
            ;
                stat(A, luk, Luk),
                random_between(1, 100, Roll),
                ( Roll =< 5 + floor(Luk * 0.1) ->
                    NCeil is Ceil + 1, NVal is Val + 1,
                    ( ceils(A, Ceils), is_dict(Ceils) -> true ; Ceils = ceils{} ),
                    NCeils = Ceils.put(Stat, NCeil),
                    A1 = A.put(xp, NXp).put(Stat, NVal).put(ceils, NCeils),
                    world:update(W, A1, NW),
                    Evts = [breakthrough(Id, Stat, NCeil, NVal)]
                ;
                    A1 = A.put(xp, NXp),
                    world:update(W, A1, NW),
                    Evts = [train_failed(Id, Stat)]
                )
            )
        )
    ).

keep_stack(S) :-
    get_dict(tag, S, Tag),
    ( config:soulbound(Tag) -> true
    ; get_dict(enchanted, S, Enc), is_list(Enc), member(permanent, Enc) -> true
    ), !.

rebirth_affs(P, NAffs) :-
    affs(P, Affs),
    ( member(aff{type: bloodline_curse, val: Val, dur: Dur}, Affs) ->
        NDur is Dur - 1,
        ( NDur > 0 -> NAffs = [aff{type: bloodline_curse, val: Val, dur: NDur}] ; NAffs = [] )
    ; NAffs = [] ).

rebirth_player(P, NP, SpawnRId) :-
    SpawnRId = temple,
    get_dict(max_hp, P, MaxHp), get_dict(max_mp, P, MaxMp),
    rebirth_affs(P, NAffs),
    ( is_special(P) ->
        NP = P.put(hp, MaxHp).put(mp, MaxMp).put(room, SpawnRId).put(affs, NAffs).put(cds, cds{})
    ;
        inv(P, Inv), include(keep_stack, Inv, NInv),
        str(P, Str), NStr is max(10, floor(Str * 0.8)),
        dex(P, Dex), NDex is max(10, floor(Dex * 0.8)),
        con(P, Con), NCon is max(10, floor(Con * 0.8)),
        int(P, Int), NInt is max(10, floor(Int * 0.8)),
        wis(P, Wis), NWis is max(10, floor(Wis * 0.8)),
        cha(P, Cha), NCha is max(10, floor(Cha * 0.8)),
        luk(P, Luk), NLuk is max(10, floor(Luk * 0.8)),
        NP = P.put(hp, MaxHp).put(mp, MaxMp).put(lvl, 1).put(xp, 0)
              .put(str, NStr).put(dex, NDex).put(con, NCon)
              .put(int, NInt).put(wis, NWis).put(cha, NCha).put(luk, NLuk)
              .put(inv, NInv).put(room, SpawnRId)
              .put(equip, equip{wpn: fists, shield: none, body: none})
              .put(affs, NAffs).put(cds, cds{})
    ).
