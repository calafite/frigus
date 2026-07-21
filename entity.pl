:- module(entity, [
    hp/2, hp/3, room/2, room/3, mp/2, mp/3,
    lvl/2, lvl/3, xp/2, xp/3, class/2, race/2,
    str/2, str/3, dex/2, dex/3, int/2, int/3,
    inv/2, inv/3, equip/2, equip/3, stat/3,
    fac/2, fac/3, affs/2, affs/3, wpn/2, alive/1,
    reps/2, reps/3, rep_val/3, rep_mod/4,
    cds/2, cds/3, total_armor/2, props/2,
    ceils/2, ceils/3, get_ceil/3,
    inv_add/4, inv_rem/4, inv_wt/2, max_wt/2,
    allowed_race/2
]).

:- use_module(config).

hp(E, E.hp).         hp(E, V, E.put(hp, V)).
room(E, E.room).     room(E, V, E.put(room, V)).
mp(E, E.mp).         mp(E, V, E.put(mp, V)).
lvl(E, E.lvl).       lvl(E, V, E.put(lvl, V)).
xp(E, E.xp).         xp(E, V, E.put(xp, V)).
class(E, E.class).
str(E, E.str).       str(E, V, E.put(str, V)).
dex(E, E.dex).       dex(E, V, E.put(dex, V)).
int(E, E.int).       int(E, V, E.put(int, V)).
inv(E, E.inv).       inv(E, V, E.put(inv, V)).
equip(E, E.equip).   equip(E, V, E.put(equip, V)).
fac(E, E.fac).       fac(E, V, E.put(fac, V)).
affs(E, A) :- get_dict(affs, E, A), !.
affs(_, []).
affs(E, V, E.put(affs, V)).

race(E, E.race) :- get_dict(race, E, _), !.
race(_, human).

props(E, P) :-
    get_dict(props, E, Base), !,
    ( race(E, Race), config:race_prop(Race, Prop) -> P = [Prop | Base] ; P = Base ).
props(_, []).

reps(E, R) :- get_dict(reps, E, R), !.
reps(_, reps{}).
reps(E, V, E.put(reps, V)).

cds(E, R) :- get_dict(cds, E, R), !.
cds(_, cds{}).
cds(E, V, E.put(cds, V)).

ceils(E, R) :- get_dict(ceils, E, R), !.
ceils(_, ceils{}).
ceils(E, V, E.put(ceils, V)).

get_ceil(E, Stat, Val) :-
    ( race(E, demigod) -> Val = 9999
    ; race(E, angel) -> Val = 9999
    ; ceils(E, Ceils), get_dict(Stat, Ceils, Val) -> true
    ; class(E, Class), config:base_ceiling(Class, Stat, Val) -> true
    ; Val = 50
    ).

rep_val(E, Fac, Val) :-
    is_dict(E, plyr),
    reps(E, Reps),
    get_dict(Fac, Reps, Val), !.
rep_val(_, _, 0).

rep_mod(E, Fac, Val, NE) :-
    is_dict(E, plyr),
    reps(E, Reps),
    ( get_dict(Fac, Reps, Cur) -> NVal is Cur + Val ; NVal = Val ),
    NReps = Reps.put(Fac, NVal),
    reps(E, NReps, NE), !.
rep_mod(E, _, _, E).

armor_val(none, 0).
armor_val(fists, 0).
armor_val(Tag, Val) :- config:armor_val(Tag, Val), !.
armor_val(_, 0).

total_armor(E, Armor) :-
    is_dict(E, plyr), !,
    equip(E, Eq),
    get_dict(shield, Eq, Shield), armor_val(Shield, SVal),
    get_dict(body, Eq, Body), armor_val(Body, BVal),
    affs(E, Affs),
    ( member(aff{type: buff, stat: body, val: BMod, dur: _}, Affs) ->
        Armor is SVal + BVal + BMod
    ;
        Armor is SVal + BVal
    ).
total_armor(_, 0).

buff_mod([], _, 0).
buff_mod([aff{type: buff, stat: S, val: V, dur: _}|T], S, Out) :- buff_mod(T, S, R), Out is R + V, !.
buff_mod([_|T], S, Out) :- buff_mod(T, S, Out).

stat(E, S, V) :-
    get_dict(S, E, Base),
    affs(E, A),
    buff_mod(A, S, Mod),
    ( race(E, Race) -> config:race_bonus(Race, S, Bonus) ; Bonus = 0 ),
    V is Base + Mod + Bonus, !.
stat(_, _, 1).

wpn(E, W) :- is_dict(E, plyr), get_dict(wpn, E.equip, W), W \== none, !.
wpn(_, fists).

alive(E) :- hp(E, Hp), Hp > 0.

inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: NQ} | R]) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R), !, NQ is OQ + Qty.
inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: Qty} | Inv]).

inv_rem(Inv, Tag, Qty, NInv) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R),
    OQ >= Qty,
    NQ is OQ - Qty,
    ( NQ =:= 0 -> NInv = R ; NInv = [stack{tag: Tag, qty: NQ} | R] ).

inv_wt([], 0).
inv_wt([stack{tag: Tag, qty: Q} | T], W) :-
    config:weight(Tag, UW),
    inv_wt(T, RW),
    W is RW + (UW * Q).

max_wt(E, W) :- stat(E, str, S), W is S * 10.

allowed_race(E, Race) :- \+ config:restricted_race(Race), !.
allowed_race(E, Race) :- config:restricted_race(Race), config:special_player(E.id).
