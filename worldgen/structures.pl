:- module(structures, [
    check_special_structure/9,
    spawn_structure_mobs/7,
    spawn_structure_features/3,
    register_respawn/1,
    tick_respawns/1
]).

:- use_module('../core/world').
:- use_module('../config/spawn').
:- use_module('spawn').
:- use_module('loot').

:- dynamic db_structure_respawn/7.

% check_special_structure(Hash, X, Y, Z, StructId, Theme, Name, Desc, Props).
check_special_structure(Hash, X, Y, Z, StructId, Theme, Name, Desc, Props) :-
    Dist is sqrt(X*X + Y*Y + Z*Z*4),
    Dist > 5,
    Roll is Hash mod 1000,
    Roll < 15, !,

    TypeRoll is (Hash // 1000) mod 7,
    structure_data(TypeRoll, StructId, Theme, BaseName, Desc),

    atomic_list_concat([BaseName, ' (Anomaly)'], Name),
    Props = [landmark, no_wander].

structure_data(0, dragons_lair, volcano, "Dragon's Lair", "Scorched earth and melted stone form a massive, smoldering crater. The air is suffocatingly hot and thick with ash.").
structure_data(1, witchs_hut, grove, "Witch's Hut", "A crooked, rotting hut sits precariously on overgrown roots. Strange, colorful fumes billow from the chimney, carrying a sickeningly sweet scent.").
structure_data(2, ancient_ruins, ruins, "Ancient Ruins", "Crumbling pillars of pale stone crackle with residual magical energy from a bygone era. Time seems to stand still here.").
structure_data(3, living_tree, forest, "The Living Tree", "A colossal tree whose branches pierce the clouds. The bark hums with a deep, rhythmic heartbeat that vibrates through the ground.").
structure_data(4, vampires_manor, keep, "Vampire's Manor", "An imposing gothic manor shrouded in unnatural darkness. The wrought iron gates are twisted into the shapes of grasping claws.").
structure_data(5, astral_rift, wild, "Astral Rift", "A tear in the fabric of reality. Fragments of floating earth drift aimlessly in a sea of starry, humming void.").
structure_data(6, necro_crypt, crypt, "Necromancer's Crypt", "An unearthed mausoleum stinking of death and decay. Green balefire flickers ominously in the surrounding braziers.").

boss_tag(dragons_lair, elder_dragon, "Elder Dragon").
boss_tag(witchs_hut, swamp_hag, "Swamp Hag").
boss_tag(ancient_ruins, ruin_golem, "Ruin Golem").
boss_tag(living_tree, ancient_treant_lord, "Ancient Treant Lord").
boss_tag(vampires_manor, vampire_lord, "Vampire Lord").
boss_tag(astral_rift, void_walker, "Void Walker").
boss_tag(necro_crypt, arch_necromancer, "Arch-Necromancer").

spawn_structure_mobs(StructId, _Hash, X, Y, Z, Theme, RId) :-
    Dist is sqrt(X*X + Y*Y + Z*Z*4),
    Lvl is max(10, floor(Dist * 1.5)),

    ( boss_tag(StructId, BossTag, CustomTitle) ->
        world:gen_id(mob, Id),
        spawn_config:mob_stats(BossTag, BHp, BStr, BDex, BInt),
        LevelMod is 1.0 + (Lvl * 0.2),
        FinalH is floor(BHp * LevelMod * 2.5), % Extremely tanky
        FinalS is max(1, floor(BStr * LevelMod * 1.5)),
        FinalD is max(1, floor(BDex * LevelMod * 1.5)),
        FinalI is max(10, floor(BInt * LevelMod * 2.8)), % Supercharged Intelligence for spellcasting

        Mob = mob{
            id: Id,
            tag: BossTag,
            name: CustomTitle,
            lvl: Lvl,
            hp: FinalH,
            max_hp: FinalH,
            str: FinalS,
            dex: FinalD,
            int: FinalI,
            room: RId,
            struct_id: StructId,
            coord_x: X,
            coord_y: Y,
            coord_z: Z,
            theme: Theme,
            props: [boss, no_wander]
        }
    ;
        spawn:gen_mob(Theme, Lvl, boss, RId, Mob)
    ),
    world:put_entity(Mob).

% Spawn structural loot features / hoards
spawn_structure_features(dragons_lair, _Hash, RId) :-
    world:gen_id(drop, GoldId),
    world:put_entity(item{id: GoldId, tag: gold, qty: 1500, room: RId}).

spawn_structure_features(ancient_ruins, _Hash, RId) :-
    proc_loot:gen_chest(15, RId, ChestItems),
    forall(member(I, ChestItems), world:put_entity(I)).

spawn_structure_features(necro_crypt, _Hash, RId) :-
    proc_loot:gen_chest(20, RId, ChestItems),
    forall(member(I, ChestItems), world:put_entity(I)).

spawn_structure_features(vampires_manor, _Hash, RId) :-
    proc_loot:gen_chest(18, RId, ChestItems),
    forall(member(I, ChestItems), world:put_entity(I)).

spawn_structure_features(witchs_hut, _Hash, RId) :-
    world:gen_id(drop, PotionId),
    world:put_entity(item{id: PotionId, tag: health_potion, qty: 3, room: RId}).

spawn_structure_features(astral_rift, _Hash, RId) :-
    world:gen_id(drop, ManaId),
    world:put_entity(item{id: ManaId, tag: mana_potion, qty: 3, room: RId}).

spawn_structure_features(living_tree, _Hash, RId) :-
    world:gen_id(drop, AppleId),
    world:put_entity(item{id: AppleId, tag: apple, qty: 5, room: RId}).

spawn_structure_features(_, _, _).

% --- Respawn System (Every 4 In-Game Hours = 240 Ticks) ---

register_respawn(DeadMob) :-
    get_dict(struct_id, DeadMob, StructId),
    get_dict(room, DeadMob, RId),
    ( get_dict(coord_x, DeadMob, X) -> true ; X = 0 ),
    ( get_dict(coord_y, DeadMob, Y) -> true ; Y = 0 ),
    ( get_dict(coord_z, DeadMob, Z) -> true ; Z = 0 ),
    ( get_dict(theme, DeadMob, Theme) -> true ; Theme = wild ),

    RespawnTicks = 240, % 240 seconds = 4 in-game hours
    retractall(db_structure_respawn(StructId, RId, _, _, _, _, _)),
    assertz(db_structure_respawn(StructId, RId, RespawnTicks, X, Y, Z, Theme)), !.
register_respawn(_).

tick_respawns(Evts) :-
    findall(r(S, R, T, X, Y, Z, Th), db_structure_respawn(S, R, T, X, Y, Z, Th), Resps),
    retractall(db_structure_respawn(_, _, _, _, _, _, _)),
    process_respawns(Resps, Evts).

process_respawns([], []).
process_respawns([r(S, R, T, X, Y, Z, Th)|Rest], Evts) :-
    NT is T - 1,
    ( NT =< 0 ->
        spawn_structure_mobs(S, 0, X, Y, Z, Th, R),
        boss_tag(S, _, Title),
        format(string(Msg), "🔥 An ancient power re-awakens! ~w has returned to its sanctuary!", [Title]),
        Evt = [env_msg(Msg)]
    ;
        assertz(db_structure_respawn(S, R, NT, X, Y, Z, Th)),
        Evt = []
    ),
    process_respawns(Rest, RestEvts),
    append(Evt, RestEvts, Evts).
