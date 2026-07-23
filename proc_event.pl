:- module(proc_event, [start_evt/4, end_evt/3]).

:- use_module(cfg_proc).
:- use_module(world).

start_evt(W, Evt, NW, [evt_start(Evt)]) :-
    cfg_proc:evt_mod(Evt, Mods),
    world:flags(W, Fs),
    active_evts(Fs, Evts),
    \+ member(Evt, Evts),
    NEvts = [Evt|Evts],
    apply_mods(Mods, Fs, TFs),
    NTFs = TFs.put(active_events, NEvts),
    world:flags(W, NTFs, NW), !.
start_evt(W, _, W, []).

end_evt(W, Evt, NW) :-
    cfg_proc:evt_mod(Evt, Mods),
    world:flags(W, Fs),
    active_evts(Fs, Evts),
    ( select(Evt, Evts, NEvts) ->
        remove_mods(Mods, Fs, TFs),
        NTFs = TFs.put(active_events, NEvts),
        world:flags(W, NTFs, NW)
    ;
        NW = W
    ), !.
end_evt(W, _, W).

active_evts(Fs, E) :- is_dict(Fs), get_dict(active_events, Fs, E), !.
active_evts(_, []).

apply_mods([], F, F).
apply_mods([M|Ms], F, NF) :-
    M =.. [K, V],
    TF = F.put(K, V),
    apply_mods(Ms, TF, NF).

remove_mods([], F, F).
remove_mods([M|Ms], F, NF) :-
    M =.. [K, _],
    ( del_dict(K, F, _, TF) -> true ; TF = F ),
    remove_mods(Ms, TF, NF).
