:- module(env, [tick_env/1, env_desc/2, local_env_desc/3]).

:- use_module('../core/world').
:- use_module(library(random)).

tick_env(Evts) :-
    world:env_state(Cur),
    get_dict(time, Cur, T), get_dict(day, Cur, D), get_dict(season, Cur, S),
    get_dict(moon, Cur, M), get_dict(mist, Cur, Mist), get_dict(weather, Cur, W),

    NT is (T + 10) mod 1440,
    ( NT < T -> ND is D + 1 ; ND is D ),

    ( ND \== D -> update_daily(ND, S, M, NS, NM, D_Evts) ; NS = S, NM = M, D_Evts = [] ),
    update_mist(Mist, NMist),

    chk_time(T, NT, TEvts),
    chk_weath(W, NW, WEvts),

    Next = env{time: NT, day: ND, season: NS, moon: NM, mist: NMist, weather: NW},
    world:put_env(Next),

    append(D_Evts, TEvts, Tmp), append(Tmp, WEvts, Evts).

update_daily(D, S, M, NS, NM, Evts) :-
    ( D mod 10 =:= 0 ->
        next_season(S, NS),
        format(string(SeasonMsg), "The winds shift. The season of ~w has begun.", [NS]),
        SEvt = [env_msg(SeasonMsg)]
    ; NS = S, SEvt = [] ),

    ( D mod 2 =:= 0 ->
        next_moon(M, NM),
        format(string(MoonMsg), "The moon transitions into a ~w phase.", [NM]),
        MEvt = [env_msg(MoonMsg)]
    ; NM = M, MEvt = [] ),

    append(SEvt, MEvt, Evts).

next_season(spring, summer).
next_season(summer, autumn).
next_season(autumn, winter).
next_season(winter, spring).

next_moon(new_moon, crescent).
next_moon(crescent, half).
next_moon(half, gibbous).
next_moon(gibbous, full_moon).
next_moon(full_moon, new_moon).

update_mist(Mist, NMist) :-
    random_between(-5, 5, Delta),
    NMist is max(0, min(100, Mist + Delta)).

chk_time(Old, New, [env_msg(Msg)]) :-
    phase(Old, P1), phase(New, P2), P1 \== P2, !,
    msg_time(P2, Msg).
chk_time(_, _, []).

phase(T, night)     :- T < 360, !.
phase(T, morning)   :- T < 720, !.
phase(T, afternoon) :- T < 1080, !.
phase(T, evening)   :- T < 1440, !.

msg_time(morning,   "The sun rises, casting a warm glow over the realm.").
msg_time(afternoon, "The sun reaches its zenith.").
msg_time(evening,   "The sun begins to set, painting the sky in hues of orange and purple.").
msg_time(night,     "Darkness falls as the stars emerge.").

chk_weath(W, NW, [env_msg(Msg)]) :-
    random_between(1, 100, R), R =< 2,
    pick_weath(NW),
    W \== NW, !,
    msg_weath(NW, Msg).
chk_weath(W, W, []).

pick_weath(NW) :- random_member(NW, [clear, overcast, precipitating, storming]).

msg_weath(clear, "The skies clear up, revealing the expanse above.").
msg_weath(overcast, "Thick clouds roll in, blocking the sky.").
msg_weath(precipitating, "Precipitation begins to fall across the lands.").
msg_weath(storming, "Thunder crashes! A violent storm has begun.").

env_desc(Cur, Desc) :-
    get_dict(time, Cur, T), get_dict(day, Cur, D), get_dict(season, Cur, S),
    get_dict(moon, Cur, M), get_dict(mist, Cur, Mist), get_dict(weather, Cur, W),
    phase(T, P), time_fmt(T, TStr),
    format(string(Desc), "Day ~w. It is ~w (~w). Season: ~w. Moon: ~w. Global Weather: ~w (Mist: ~w%).", [D, P, TStr, S, M, W, Mist]).

local_env_desc(Room, Env, Desc) :-
    ( get_dict(env, Room, REnv) ->
        get_dict(temp, REnv, TBase), get_dict(magic, REnv, M), get_dict(corr, REnv, C)
    ;
        TBase = 15, M = 10, C = 0 % Fallback for legacy rooms without 'env' node
    ),
    get_dict(season, Env, Season), get_dict(weather, Env, Weather),

    ( Season == spring -> Mod = 0
    ; Season == summer -> Mod = 15
    ; Season == autumn -> Mod = 0
    ; Season == winter -> Mod = -15 ),
    Temp is TBase + Mod,

    ( Temp =< 0, Weather == precipitating -> LocalW = "Snowing"
    ; Temp > 0, Weather == precipitating -> LocalW = "Raining"
    ; LocalW = Weather ),

    format(string(Desc), "Weather: ~w | Temp: ~w°C | Ambient Magic: ~w | Corruption: ~w", [LocalW, Temp, M, C]).

time_fmt(T, Str) :-
    H is T div 60, M is T mod 60,
    format(string(Str), "~|~`0t~w~2+:~|~`0t~w~2+", [H, M]).
