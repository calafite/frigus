:- module(proc_event, [start_evt/4, end_evt/3]).

:- use_module(cfg_proc).

start_evt(W, Evt, NW, [evt_start(Evt)]) :-
    evt_mod(Evt, Mods),
    flags(W, Fs),
    active_evts(Fs, Evts),
    \+ member(Evt, Evts),
    NEvts = [Evt|Evts],
    apply_mods(Mods, Fs, TFs),
    NTFs = TFs.put(active_events, NEvts),
    flags(W, NTFs, NW).

end_evt(W, Evt, NW) :-
    evt_mod(Evt, Mods),
    flags(W, Fs),
    active_evts(Fs, Evts),
    select(Evt, Evts, NEvts),
    remove_mods(Mods, Fs, TFs),
    NTFs = TFs.put(active_events, NEvts),
    flags(W, NTFs, NW).

active_evts(Fs, E) :- get_dict(active_events, Fs, E), !.
active_evts(_, []).

flags(W, F) :- get_dict(flags, W, F), !.
flags(_, flags{}).
flags(W, V, W.put(flags, V)).

apply_mods([], F, F).
apply_mods([M|Ms], F, NF) :-
    M =.. [K, V],
    TF = F.put(K, V),
    apply_mods(Ms, TF, NF).

remove_mods([], F, F).
remove_mods([M|Ms], F, NF) :-
    M =.. [K, _],
    del_dict(K, F, _, TF),
    remove_mods(Ms, TF, NF).
