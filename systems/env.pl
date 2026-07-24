:- module(env, [tick_env/1, env_desc/2, local_env_desc/3]).

:- use_module('../core/world').
:- use_module(library(random)).

to_atom(Var, unknown) :- var(Var), !.
to_atom(Atom, Atom) :- atom(Atom), !.
to_atom(String, Atom) :- string(String), !, atom_string(Atom, String).
to_atom(Number, Atom) :- number(Number), !, atom_number(Atom, Number).
to_atom(_, unknown).

tick_env(Evts) :-
    world:env_state(Cur),
    ( get_dict(time, Cur, T) -> true ; T = 480 ),
    ( get_dict(day, Cur, D) -> true ; D = 1 ),
    ( get_dict(season, Cur, RawS) -> to_atom(RawS, S) ; S = spring ),
    ( get_dict(moon, Cur, RawM) -> to_atom(RawM, M) ; M = full_moon ),
    ( get_dict(mist, Cur, Mist) -> true ; Mist = 0 ),
    ( get_dict(weather, Cur, RawW) -> to_atom(RawW, W) ; W = clear ),

    % Advance 1 minute per tick (1 second real-time = 1 minute game time -> 24 min full day)
    NT is (T + 1) mod 1440,
    ( NT < T -> ND is D + 1 ; ND is D ),

    ( ND \== D -> update_daily(ND, S, M, NS, NM, D_Evts) ; NS = S, NM = M, D_Evts = [] ),

    % Fluctuate mist gradually (10% chance per tick)
    ( random_between(1, 10, 1) -> update_mist(Mist, NMist) ; NMist = Mist ),

    chk_time(T, NT, TEvts),
    chk_weath(W, NW, WEvts),

    Next = env{time: NT, day: ND, season: NS, moon: NM, mist: NMist, weather: NW},
    world:put_env(Next),

    append(D_Evts, TEvts, Tmp), append(Tmp, WEvts, Evts).

update_daily(D, S, M, NS, NM, Evts) :-
    ( D mod 10 =:= 0 ->
        next_season(S, NS),
        msg_season(NS, SeasonMsg),
        SEvt = [env_msg(SeasonMsg)]
    ; NS = S, SEvt = [] ),

    ( D mod 2 =:= 0 ->
        next_moon(M, NM),
        msg_moon(NM, MoonMsg),
        MEvt = [env_msg(MoonMsg)]
    ; NM = M, MEvt = [] ),

    append(SEvt, MEvt, Evts).

next_season(spring, summer).
next_season(summer, autumn).
next_season(autumn, winter).
next_season(winter, spring).
next_season(_, spring).

next_moon(new_moon, crescent).
next_moon(crescent, half).
next_moon(half, gibbous).
next_moon(gibbous, full_moon).
next_moon(full_moon, new_moon).
next_moon(_, full_moon).

update_mist(Mist, NMist) :-
    random_between(-3, 3, Delta),
    NMist is max(0, min(100, Mist + Delta)).

chk_time(Old, New, [env_msg(Msg)]) :-
    phase(Old, P1), phase(New, P2), P1 \== P2, !,
    msg_time(P2, Msg).
chk_time(_, _, []).

phase(T, night)     :- T < 360, !.
phase(T, morning)   :- T < 720, !.
phase(T, afternoon) :- T < 1080, !.
phase(T, evening)   :- T < 1440, !.

chk_weath(W, NW, [env_msg(Msg)]) :-
    random_between(1, 1000, R), R =< 2, % ~0.2% chance per tick (~8-10 minutes between weather changes)
    pick_weath(NW),
    W \== NW, !,
    msg_weath(NW, Msg).
chk_weath(W, W, []).

pick_weath(NW) :- random_member(NW, [clear, overcast, precipitating, storming]).

% --- Configurable Atmospheric Messages ---

msg_time(morning,   "🌅 As the sun peeks over the horizon, warm morning light washes across the realm.").
msg_time(afternoon, "☀️ The sun reaches its zenith, bathing the land in brilliant daylight.").
msg_time(evening,   "🌆 Shadows lengthen as the sun sinks in fiery hues of crimson and gold.").
msg_time(night,     "🌙 Darkness envelopes the land as night falls and stars flicker to life.").

msg_season(spring, "🌸 A gentle breeze warms the air as flowers bloom—Spring has arrived.").
msg_season(summer, "☀️ Golden light bathes the realm as Summer brings intense warmth.").
msg_season(autumn, "🍂 Leaves turn amber and crisp winds sweep through the realm—Autumn is here.").
msg_season(winter, "❄️ A piercing chill grips the world as Winter lays its icy blanket.").

msg_moon(new_moon,   "🌑 The moon fades into total shadow, leaving the night sky pitch black.").
msg_moon(crescent,   "🌒 A faint sliver of silver moon illuminates the night sky.").
msg_moon(half,       "🌓 Half of the pale moon shines brightly overhead.").
msg_moon(gibbous,    "🌔 The waxing moon swells, filling the night with soft radiance.").
msg_moon(full_moon,  "🌕 The Full Moon hangs radiant! Monsters grow restless and surge with power!").

msg_weath(clear,         "🌤️ The clouds part, opening up clear skies above.").
msg_weath(overcast,      "☁️ A heavy grey mantle of clouds gathers over the land.").
msg_weath(precipitating, "🌧️ Cloud cover thickens as precipitation begins to fall.").
msg_weath(storming,      "⚡ Lightning flashes and thunder rumbles violently across the heavens!").

env_desc(Cur, Desc) :-
    ( get_dict(time, Cur, T) -> true ; T = 480 ),
    ( get_dict(day, Cur, D) -> true ; D = 1 ),
    ( get_dict(season, Cur, RawS) -> to_atom(RawS, S) ; S = spring ),
    ( get_dict(moon, Cur, RawM) -> to_atom(RawM, M) ; M = full_moon ),
    ( get_dict(mist, Cur, Mist) -> true ; Mist = 0 ),
    ( get_dict(weather, Cur, RawW) -> to_atom(RawW, W) ; W = clear ),
    phase(T, P), time_fmt(T, TStr),
    format(string(Desc), "Day ~w. It is ~w (~w). Season: ~w. Moon: ~w. Global Weather: ~w (Mist: ~w%).", [D, P, TStr, S, M, W, Mist]).

local_env_desc(Room, Env, Desc) :-
    ( get_dict(env, Room, REnv) ->
        ( get_dict(temp, REnv, TBase) -> true ; TBase = 15 ),
        ( get_dict(magic, REnv, M) -> true ; M = 10 ),
        ( get_dict(corr, REnv, C) -> true ; C = 0 )
    ;
        TBase = 15, M = 10, C = 0
    ),
    ( get_dict(season, Env, RawSeason) -> to_atom(RawSeason, Season) ; Season = spring ),
    ( get_dict(weather, Env, RawWeather) -> to_atom(RawWeather, Weather) ; Weather = clear ),
    ( get_dict(time, Env, T) -> true ; T = 480 ),
    ( get_dict(moon, Env, RawMoon) -> to_atom(RawMoon, Moon) ; Moon = full_moon ),

    phase(T, Phase),
    time_fmt(T, TStr),
    display_season(Season, SeasonStr),
    display_phase(Phase, PhaseStr),

    ( Phase == night ->
        display_moon(Moon, MoonStr),
        format(string(TimeStr), "~w ~w (~w)", [PhaseStr, TStr, MoonStr])
    ;
        format(string(TimeStr), "~w ~w", [PhaseStr, TStr])
    ),

    ( Season == spring -> Mod = 0
    ; Season == summer -> Mod = 15
    ; Season == autumn -> Mod = 0
    ; Season == winter -> Mod = -15
    ; Mod = 0 ),
    Temp is TBase + Mod,

    ( Temp =< 0, Weather == precipitating -> LocalW = "Snowing"
    ; Temp > 0, Weather == precipitating -> LocalW = "Raining"
    ; display_weather(Weather, LocalW) ),

    format(string(Desc), "~w | ~w | Weather: ~w | Temp: ~w°C | Ambient Magic: ~w | Corruption: ~w", [SeasonStr, TimeStr, LocalW, Temp, M, C]).

time_fmt(T, Str) :-
    H is T div 60, M is T mod 60,
    format(string(Str), "~|~`0t~w~2+:~|~`0t~w~2+", [H, M]).

% --- Presentation Helpers ---

display_season(spring, "Spring") :- !.
display_season(summer, "Summer") :- !.
display_season(autumn, "Autumn") :- !.
display_season(winter, "Winter") :- !.
display_season(S, SStr) :- atom_string(S, SStr).

display_phase(morning, "Morning") :- !.
display_phase(afternoon, "Afternoon") :- !.
display_phase(evening, "Evening") :- !.
display_phase(night, "Night") :- !.
display_phase(P, PStr) :- atom_string(P, PStr).

display_weather(clear, "Clear") :- !.
display_weather(overcast, "Overcast") :- !.
display_weather(precipitating, "Precipitating") :- !.
display_weather(storming, "Storming") :- !.
display_weather(W, WStr) :- atom_string(W, WStr).

display_moon(new_moon, "New Moon") :- !.
display_moon(crescent, "Crescent Moon") :- !.
display_moon(half, "Half Moon") :- !.
display_moon(gibbous, "Gibbous Moon") :- !.
display_moon(full_moon, "Full Moon") :- !.
display_moon(M, MStr) :- atom_string(M, MStr).
