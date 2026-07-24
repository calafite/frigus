:- module(info, [do_look/2, do_status/2, do_inventory/2, do_bounties/2, do_time/2, do_help/2]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('env').

is_plyr(E) :- is_dict(E, plyr), !.
is_plyr(E) :- is_dict(E), get_dict(tag, E, player).

is_item(E) :- is_dict(E, item), !.
is_item(E) :- is_dict(E), get_dict(qty, E, _).

is_mob(E) :- is_dict(E, mob), !.
is_mob(E) :- is_dict(E), \+ is_plyr(E), \+ is_item(E), get_dict(hp, E, _).

do_look(Id, Evts) :-
    ( world:get_entity(Id, A) ->
        get_dict(room, A, RoomId),
        ( world:get_room(RoomId, Node) ->
            get_dict(id, Node, RId),
            ( get_dict(desc, Node, Desc) -> true ; Desc = "A room." ),
            ( get_dict(props, Node, Props) -> true ; Props = [] ),
            ( get_dict(exits, Node, ExitsDict), dict_keys(ExitsDict, Exits) -> true ; Exits = [] ),
            world:room_entities(RId, Ents),
            get_dict(hp, A, SelfHp), get_dict(max_hp, A, SelfMaxHp),
            get_dict(mp, A, SelfMp), get_dict(max_mp, A, SelfMaxMp),
            ( get_dict(affs, A, SelfAffs) -> true ; SelfAffs = dict{} ),
            SelfStats = dict{hp: SelfHp, max_hp: SelfMaxHp, mp: SelfMp, max_mp: SelfMaxMp, affs: SelfAffs},

            ( world:env_state(EnvState), catch(env:local_env_desc(Node, EnvState, EnvDesc), _, EnvDesc = "") -> true ; EnvDesc = "" ),

            findall(dict{id: OId, hp: OHp, max_hp: OMaxHp, bounty: OBty, affs: OAffs},
                    (member(O, Ents), is_plyr(O), get_dict(id, O, OId), OId \== Id,
                     get_dict(hp, O, OHp), get_dict(max_hp, O, OMaxHp), (get_dict(bounty, O, OBty) -> true ; OBty = 0), (get_dict(affs, O, OAffs) -> true ; OAffs = dict{})), OData),
            findall(dict{id: MId, name: MName, tag: MTag, hp: MHp, max_hp: MMaxHp, affs: MAffs},
                    (member(M, Ents), is_mob(M), get_dict(hp, M, MHp), MHp > 0,
                     get_dict(id, M, MId), (get_dict(name, M, MName) -> true ; MName = MTag),
                     get_dict(tag, M, MTag), (get_dict(max_hp, M, MMaxHp) -> true ; MMaxHp = MHp), (get_dict(affs, M, MAffs) -> true ; MAffs = dict{})), MData),
            findall(dict{id: IId, tag: ITag, qty: IQty},
                    (member(I, Ents), is_item(I), get_dict(id, I, IId),
                     get_dict(tag, I, ITag), get_dict(qty, I, IQty)), IData),
            Evts = [look(RId, Desc, Props, Exits, OData, MData, IData, SelfStats, EnvDesc)]
        ; Evts = [error(room_not_found(RoomId))] )
    ; Evts = [error(actor_not_found(Id))] ).

do_status(Id, [status_info(Id, Lvl, Xp, ReqXp, StatPoints, Stats, Health, Bty)]) :-
    world:get_entity(Id, A), !,
    get_dict(hp, A, Hp), get_dict(max_hp, A, MaxHp),
    get_dict(mp, A, Mp), get_dict(max_mp, A, MaxMp),
    get_dict(lvl, A, Lvl), get_dict(xp, A, Xp),
    ( get_dict(affs, A, Affs) -> true ; Affs = dict{} ),
    ReqXp is Lvl * Lvl * 100,
    ( get_dict(stat_points, A, StatPoints) -> true ; StatPoints = 0 ),
    ( get_dict(bounty, A, Bty) -> true ; Bty = 0 ),
    entity:get_stat(A, str, Str), entity:get_stat(A, dex, Dex),
    entity:get_stat(A, con, Con), entity:get_stat(A, int, Int),
    entity:get_stat(A, wis, Wis), entity:get_stat(A, cha, Cha),
    entity:get_stat(A, luk, Luk),
    Stats = dict{str: Str, dex: Dex, con: Con, int: Int, wis: Wis, cha: Cha, luk: Luk},
    Health = dict{hp: Hp, max_hp: MaxHp, mp: Mp, max_mp: MaxMp, affs: Affs}.
do_status(Id, [error(actor_not_found(Id))]).

do_inventory(Id, [inventory_info(Id, Inv, Eq)]) :-
    world:get_entity(Id, A), !, get_dict(inv, A, Inv), get_dict(equip, A, Eq).
do_inventory(Id, [error(actor_not_found(Id))]).

do_bounties(Id, [bounty_report(Id, List)]) :- world:get_bounty_leaderboard(10, List).
do_time(Id, [time_report(Id, Desc)]) :- world:env_state(Env), env:env_desc(Env, Desc).

do_help(Id, [help_info(Id, Text)]) :-
    Text = "<div style='border: 1px solid var(--accent); padding: 12px; border-radius: 6px; background: var(--bg-surface); margin: 6px 0;'>
      <strong style='color: var(--accent); font-size: 1.05rem;'>--- COMMAND HELP ---</strong><br>
      <div style='margin-top: 8px; line-height: 1.6;'>
        • <strong>look / l</strong> — Inspect current location<br>
        • <strong>n / s / e / w / u / d</strong> — Directional movement<br>
        • <strong>go &lt;exit&gt;</strong> — Move to custom exit (e.g. <i>go wild</i>)<br>
        • <strong>k / kill &lt;target&gt;</strong> — Attack target (e.g. <i>k goblin</i>)<br>
        • <strong>c / cast &lt;spell&gt; [target]</strong> — Cast spell (e.g. <i>c mend</i>, <i>c fireball orc</i>)<br>
        • <strong>get / g &lt;item&gt;</strong> — Pick up item from ground<br>
        • <strong>equip / unequip</strong> — Manage weapon and armor slots<br>
        • <strong>use &lt;item&gt;</strong> — Consume potion or food<br>
        • <strong>train / allocate &lt;stat&gt;</strong> — Train stat points (e.g. <i>train str</i>)<br>
        • <strong>status / inv / time / bounty</strong> — View character & realm status
      </div>
    </div>".
