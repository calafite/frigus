:- module(entity, [
    hp/2, hp/3, room/2, room/3, mp/2, mp/3,
    lvl/2, lvl/3, xp/2, xp/3, class/2, race/2,
    str/2, str/3, dex/2, dex/3, con/2, con/3,
    int/2, int/3, wis/2, wis/3, cha/2, cha/3, luk/2, luk/3,
    inv/2, inv/3, equip/2, equip/3, stat/3, base_stat/3,
    fac/2, fac/3, affs/2, affs/3, wpn/2, alive/1,
    reps/2, reps/3, rep_val/3, rep_mod/4,
    cds/2, cds/3, total_armor/2, props/2,
    ceils/2, ceils/3, get_ceil/3, is_special/1,
    skills/2, skills/3, skill_val/3, skill_mod/4,
    quests/2, quests/3, threats/2, threats/3,
    altitude/2, altitude/3, climb_state/2, climb_state/3,
    stance/2, stance/3, mount/2, mount/3, torch_life/2, torch_life/3,
    job/2, job/3, home/2, home/3, work/2, work/3,
    act_state/2, act_state/3, mems/2, mems/3, bounty/2, bounty/3,
    gender/2, gender/3, is_encumbered/1,
    inv_add/4, inv_rem/4, inv_wt/2, max_wt/2,
    allowed_race/2
]).

:- use_module(config).
:- use_module(cfg_combat).

hp(E, Hp)         :- get_dict(hp, E, Hp).         hp(E, V, E.put(hp, V)).
room(E, Room)     :- get_dict(room, E, Room).     room(E, V, E.put(room, V)).
mp(E, Mp)         :- get_dict(mp, E, Mp).         mp(E, V, E.put(mp, V)).
lvl(E, Lvl)       :- get_dict(lvl, E, Lvl).       lvl(E, V, E.put(lvl, V)).
xp(E, Xp)         :- get_dict(xp, E, Xp).         xp(E, V, E.put(xp, V)).
class(E, Class)   :- get_dict(class, E, Class).

str(E, V)         :- get_dict(str, E, V).         str(E, V, E.put(str, V)).
dex(E, V)         :- get_dict(dex, E, V).         dex(E, V, E.put(dex, V)).
con(E, V)         :- get_dict(con, E, V).         con(E, V, E.put(con, V)).
int(E, V)         :- get_dict(int, E, V).         int(E, V, E.put(int, V)).
wis(E, V)         :- get_dict(wis, E, V).         wis(E, V, E.put(wis, V)).
cha(E, V)         :- get_dict(cha, E, V).         cha(E, V, E.put(cha, V)).
luk(E, V)         :- get_dict(luk, E, V).         luk(E, V, E.put(luk, V)).

inv(E, V)         :- get_dict(inv, E, V).         inv(E, V, E.put(inv, V)).
equip(E, V)       :- get_dict(equip, E, V).       equip(E, V, E.put(equip, V)).
fac(E, V)         :- get_dict(fac, E, V).         fac(E, V, E.put(fac, V)).

affs(E, A) :- get_dict(affs, E, A), !.
affs(_, []).
affs(E, V, E.put(affs, V)).

threats(E, T) :- get_dict(threats, E, T), !.
threats(_, dict{}).
threats(E, V, E.put(threats, V)).

bounty(E, B) :- get_dict(bounty, E, B), !.
bounty(_, 0).
bounty(E, V, E.put(bounty, V)).

race(E, Race) :-
    is_dict(E),
    get_dict(race, E, Race), !.
race(_, human).

props(E, P) :-
    get_dict(props, E, Base), !,
    ( race(E, Race) -> findall(Prop, config:race_prop(Race, Prop), RProps) ; RProps = [] ),
    append(RProps, Base, P1),
    ( mount(E, Mount), Mount \== none -> P2 = [Mount | P1] ; P2 = P1 ),
    ( member(griffin, P2) -> P = [flight | P2] ; P = P2 ).
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

quests(E, Q) :- get_dict(quests, E, Q), !.
quests(_, quests{}).
quests(E, V, E.put(quests, V)).

altitude(E, A) :- get_dict(altitude, E, A), !.
altitude(_, ground).
altitude(E, V, E.put(altitude, V)).

climb_state(E, C) :- get_dict(climb_state, E, C), !.
climb_state(_, false).
climb_state(E, V, E.put(climb_state, V)).

stance(E, S) :- get_dict(stance, E, S), !.
stance(_, walk).
stance(E, V, E.put(stance, V)).

mount(E, M) :- get_dict(mount, E, M), !.
mount(_, none).
mount(E, V, E.put(mount, V)).

torch_life(E, L) :- get_dict(torch_life, E, L), !.
torch_life(_, 100).
torch_life(E, V, E.put(torch_life, V)).

job(E, J) :- get_dict(job, E, J), !.
job(_, none).
job(E, V, E.put(job, V)).

home(E, H) :- get_dict(home, E, H), !.
home(_, none).
home(E, V, E.put(home, V)).

work(E, W) :- get_dict(work, E, W), !.
work(_, none).
work(E, V, E.put(work, V)).

act_state(E, S) :- get_dict(act_state, E, S), !.
act_state(_, wander).
act_state(E, V, E.put(act_state, V)).

mems(E, M) :- get_dict(mems, E, M), !.
mems(_, mems{}).
mems(E, V, E.put(mems, V)).

gender(E, G) :- get_dict(gender, E, G), !.
gender(_, male).
gender(E, G, E.put(gender, G)).

is_encumbered(E) :-
    inv(E, Inv), inv_wt(Inv, Wt), max_wt(E, Max),
    Wt > Max * 0.7.

get_ceil(E, Stat, Val) :-
    ( race(E, demigod) -> Val = 9999
    ; race(E, angel) -> Val = 9999
    ; ceils(E, Ceils), get_dict(Stat, Ceils, Val) -> true
    ; class(E, Class), config:base_ceiling(Class, Stat, Val) -> true
    ; Val = 50
    ).

skills(E, S) :- get_dict(skills, E, S), !.
skills(_, skills{}).
skills(E, V, E.put(skills, V)).

skill_val(E, Skill, Val) :-
    skills(E, S), get_dict(Skill, S, Val), !.
skill_val(_, _, 1).

skill_mod(E, Skill, Val, NE) :-
    skills(E, S),
    ( get_dict(Skill, S, Cur) -> NVal is Cur + Val ; NVal = Val ),
    NS = S.put(Skill, NVal), skills(E, NS, NE).

rep_val(E, Fac, Val) :-
    is_dict(E, plyr), reps(E, Reps), get_dict(Fac, Reps, Val), !.
rep_val(_, _, 0).

rep_mod(E, Fac, Val, NE) :-
    is_dict(E, plyr), reps(E, Reps),
    ( get_dict(Fac, Reps, Cur) -> NVal is Cur + Val ; NVal = Val ),
    NReps = Reps.put(Fac, NVal), reps(E, NReps, NE), !.
rep_mod(E, _, _, E).

item_armor(none, 0) :- !.
item_armor(Item, Val) :-
    is_dict(Item, item), get_dict(tag, Item, Tag), !,
    config:armor_val(Tag, Base),
    ( get_dict(props, Item, Props), member(prop(ArmorProp, M), Props), ArmorProp == armor -> Val is Base + M ; Val = Base ).
item_armor(Tag, Val) :- config:armor_val(Tag, Val), !.
item_armor(_, 0).

total_armor(E, Armor) :-
    is_dict(E, plyr), !, equip(E, Eq),
    get_dict(shield, Eq, Shield), item_armor(Shield, SVal),
    get_dict(body, Eq, Body), item_armor(Body, BVal),
    affs(E, Affs),
    ( stance(E, crawl) -> StBonus = 10 ; StBonus = 0 ),
    ( member(aff{type: buff, stat: body, val: BMod, dur: _}, Affs) ->
        Armor is SVal + BVal + BMod + StBonus
    ; Armor is SVal + BVal + StBonus ).
total_armor(E, Armor) :-
    is_dict(E, mob), props(E, Props),
    findall(A, member(prop(armor, A), Props), AVals),
    sum_list(AVals, Armor), !.
total_armor(_, 0).

buff_mod([], _, 0).
buff_mod([aff{type: buff, stat: S, val: V, dur: _}|T], S, Out) :- buff_mod(T, S, R), Out is R + V, !.
buff_mod([aff{type: plague, val: _, dur: _}|T], S, Out) :- buff_mod(T, S, R), Out is R - 5, !.
buff_mod([aff{type: fever, val: _, dur: _}|T], S, Out) :- (S == int -> buff_mod(T, S, R), Out is R - 10, ! ; buff_mod(T, S, Out)).
buff_mod([_|T], S, Out) :- buff_mod(T, S, Out).

equip_stat_mod(E, Stat, Total) :-
    equip(E, Eq), dict_pairs(Eq, _, Pairs),
    findall(Val, (
        member(_-Item, Pairs), is_dict(Item, item),
        get_dict(props, Item, Props), member(prop(Stat, Val), Props)
    ), Vals),
    sum_list(Vals, Total).

base_stat(_, none, 9999) :- !.
base_stat(E, S, V) :-
    get_dict(S, E, Base), affs(E, A), buff_mod(A, S, Mod),
    ( race(E, Race), config:race_bonus(Race, S, Bonus) -> true ; Bonus = 0 ),
    ( stance(E, crawl) -> (S == dex -> StMod = -5 ; S == str -> StMod = -3 ; StMod = 0) ; StMod = 0 ),
    ( is_dict(E, plyr) -> equip_stat_mod(E, S, EqMod) ; EqMod = 0 ),
    V is Base + Mod + Bonus + StMod + EqMod, !.
base_stat(_, _, 1).

stat(_, none, 9999) :- !.
stat(E, S, V) :-
    base_stat(E, S, BaseV),
    ( is_encumbered(E) -> (S == dex -> EncMod = -8 ; S == str -> EncMod = -4 ; EncMod = 0) ; EncMod = 0 ),
    V is BaseV + EncMod, !.
stat(_, _, 1).

wpn(E, W) :-
    is_dict(E, plyr), get_dict(equip, E, Eq), get_dict(wpn, Eq, WObj), WObj \== none,
    (is_dict(WObj, item) -> get_dict(tag, WObj, W) ; W = WObj), !.
wpn(E, Tag) :-
    is_dict(E, mob), get_dict(tag, E, Tag), cfg_combat:wpn_dmg(Tag, _), !.
wpn(_, fists).

alive(E) :-
    is_dict(E),
    get_dict(hp, E, Hp),
    Hp > 0.

inv_add(Inv, Item, _Qty, [Item | Inv]) :-
    is_dict(Item, item), !.
inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: NQ} | R]) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R), !, NQ is OQ + Qty.
inv_add(Inv, Tag, Qty, [stack{tag: Tag, qty: Qty} | Inv]).

inv_rem(Inv, ItemId, 1, NInv) :-
    atom(ItemId), select(Item, Inv, NInv), is_dict(Item, item), Item.id == ItemId, !.
inv_rem(Inv, Tag, Qty, NInv) :-
    select(stack{tag: Tag, qty: OQ}, Inv, R),
    OQ >= Qty, NQ is OQ - Qty,
    ( NQ =:= 0 -> NInv = R ; NInv = [stack{tag: Tag, qty: NQ} | R] ), !.
inv_rem(Inv, Tag, 1, NInv) :-
    select(Item, Inv, NInv), is_dict(Item, item), Item.tag == Tag.

inv_wt([], 0).
inv_wt([Item | T], W) :-
    is_dict(Item, item), config:weight(Item.tag, UW), !,
    inv_wt(T, RW), W is RW + UW.
inv_wt([stack{tag: Tag, qty: Q} | T], W) :-
    config:weight(Tag, UW), inv_wt(T, RW), W is RW + (UW * Q).

max_wt(E, W) :-
    base_stat(E, str, S), base_stat(E, con, C),
    mount(E, Mount),
    ( Mount == horse -> Extra = 200 ; Mount == griffin -> Extra = 300 ; Extra = 0 ),
    W is (S * 7) + (C * 3) + Extra.

allowed_race(_E, Race) :- \+ config:restricted_race(Race), !.
allowed_race(E, Race) :- config:restricted_race(Race), config:special_player(E.id).

is_special(E) :- get_dict(race, E, Race), config:restricted_race(Race), !.
is_special(E) :- config:special_player(E.id).
