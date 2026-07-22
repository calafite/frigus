:- module(env, [tick_env/3, db_env/1]).

:- use_module(library(random)).

:- dynamic db_env/1.

tick_env(W, db, [time_passed(NHr, NMin), weather_changed(NWeath), moon_shifted(NMoon)]) :-
    get_env(W, Env),
    Min = Env.min, Hr = Env.hr, Day = Env.day, Mon = Env.mon,
    NMin is (Min + 10) mod 60,
    ( NMin == 0 -> NHr is (Hr + 1) mod 24 ; NHr = Hr ),
    ( (NHr == 0, NMin == 0) -> NDay is (Day mod 30) + 1 ; NDay = Day ),
    ( (NDay == 1, NHr == 0, NMin == 0) -> NMon is (Mon mod 12) + 1 ; NMon = Mon ),
    get_season(NMon, NSeas),
    ( (NHr mod 4 == 0, NMin == 0) -> roll_weather(NSeas, NWeath) ; NWeath = Env.weath ),
    MDay is NDay mod 8,
    get_moon(MDay, NMoon),
    NEnv = env{hr: NHr, min: NMin, day: NDay, mon: NMon, seas: NSeas, weath: NWeath, moon: NMoon},
    retractall(db_env(_)),
    assertz(db_env(NEnv)).

get_env(_, Env) :- db_env(Env), !.
get_env(_, env{hr: 12, min: 0, day: 1, mon: 1, seas: spring, weath: clear, moon: new_moon}).

get_season(M, spring) :- M >= 1, M =< 3, !.
get_season(M, summer) :- M >= 4, M =< 6, !.
get_season(M, autumn) :- M >= 7, M =< 9, !.
get_season(_, winter).

get_moon(0, new_moon).
get_moon(1, waxing_crescent).
get_moon(2, first_quarter).
get_moon(3, waxing_gibbous).
get_moon(4, full_moon).
get_moon(5, waning_gibbous).
get_moon(6, third_quarter).
get_moon(7, waning_crescent).

roll_weather(spring, W) :-
    random_between(1, 100, R),
    ( R =< 60 -> W = clear ; R =< 90 -> W = rain ; W = storm ).
roll_weather(summer, W) :-
    random_between(1, 100, R),
    ( R =< 70 -> W = clear ; R =< 90 -> W = heatwave ; W = rain ).
roll_weather(autumn, W) :-
    random_between(1, 100, R),
    ( R =< 40 -> W = clear ; R =< 80 -> W = rain ; W = storm ).
roll_weather(winter, W) :-
    random_between(1, 100, R),
    ( R =< 40 -> W = clear ; R =< 80 -> W = snow ; W = blizzard ).
