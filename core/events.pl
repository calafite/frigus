:- module(events, [split_events/3, is_public_event/1]).

is_public_event(moved(_,_,_)).
is_public_event(moved(_,_,_,_)).
is_public_event(hit(_,_,_,_,_)).
is_public_event(crit(_,_,_,_,_)).
is_public_event(dead(_,_)).

% Spell casting events
is_public_event(cast(_,_,_)).
is_public_event(cast_area(_,_)).
is_public_event(cast_group(_,_)).
is_public_event(healed(_,_,_,_)).
is_public_event(spell_missed(_,_)).

is_public_event(dodged(_,_)).
is_public_event(flurry(_,_)).
is_public_event(say(_,_)).
is_public_event(npc_arrived(_)).
is_public_event(guard_reinforcement(_)).
is_public_event(bounty_paid(_,_)).
is_public_event(env_msg(_)).

% Status effects
is_public_event(aff_applied(_,_)).
is_public_event(aff_tick(_,_,_)).
is_public_event(aff_faded(_,_)).

split_events([], [], []).
split_events([E|Es], [E|Pubs], Privs) :- is_public_event(E), !, split_events(Es, Pubs, Privs).
split_events([E|Es], Pubs, [E|Privs]) :- split_events(Es, Pubs, Privs).
