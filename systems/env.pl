:- module(env, [tick_env/1, env_desc/2]).

:- use_module('../core/world').
:- use_module(library(random)).

tick_env(Evts) :-
    world:env_state(Cur),
    get_dict(time, Cur, T),
    get_dict(weather, Cur, W),
    NT is (T + 10) mod 1440,
    chk_time(T, NT, TEvts),
    chk_weath(W, NW, WEvts),
    Next = Cur.put(time, NT).put(weather, NW),
    world:put_env(Next),
    append(TEvts, WEvts, Evts).

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
    random_between(1, 100, R), R =< 2, !,
    pick_weath(NW),
    W \== NW,
    msg_weath(NW, Msg).
chk_weath(W, W, []).

pick_weath(NW) :-
    random_member(NW, [clear, rain, storm, snow]).

msg_weath(clear, "The skies clear up, revealing the expanse above.").
msg_weath(rain,  "Dark clouds gather and rain begins to fall.").
msg_weath(storm, "Thunder crashes! A violent storm has begun.").
msg_weath(snow,  "A gentle snow starts to drift down from the cold sky.").

env_desc(Cur, Desc) :-
    get_dict(time, Cur, T),
    get_dict(weather, Cur, W),
    phase(T, P),
    time_fmt(T, TStr),
    format(string(Desc), "It is ~w (~w). The weather is ~w.", [P, TStr, W]).

time_fmt(T, Str) :-
    H is T div 60, M is T mod 60,
    format(string(Str), "~|~`0t~w~2+:~|~`0t~w~2+", [H, M]).
