:- module(combat_factions, [
              is_valid_combat_target/1, is_town_npc/1, is_innocent/1, is_crime/1,
              get_proxy_ent/2, in_same_party/2, is_enemy/2, is_friendly/2,
              resolve_target/3, get_room_targets/3, filter_targets/4,
              do_pay_bounty/2, clear_local_threats/2
                           ]).

:- use_module('../../core/world').
:- use_module('../../core/entity').
:- use_module('core').
:- use_module(library(lists)).

is_valid_combat_target(Ent) :- is_dict(Ent, plyr).
is_valid_combat_target(Ent) :- is_dict(Ent, mob).

is_town_npc(Ent) :- get_dict(tag, Ent, RawTag), combat_core:to_atom(RawTag, Tag), member(Tag, [guard, peasant, merchant, priest, miner]), !.
is_town_npc(Ent) :- get_dict(fac, Ent, RawFac), combat_core:to_atom(RawFac, Fac), member(Fac, [guard, citizen, merchant]), !.

is_innocent(Ent) :- is_town_npc(Ent) ; is_dict(Ent, plyr).
is_crime(Tgt) :- is_innocent(Tgt), ( get_dict(bounty, Tgt, B) -> B =< 0 ; true ).

get_proxy_ent(Ent, Proxy) :-
    is_dict(Ent), get_dict(owner, Ent, OwnerId), world:get_entity(OwnerId, Proxy), !.
get_proxy_ent(Ent, Ent).

% Check if two entities are in the same party
in_same_party(A, B) :-
    is_dict(A), is_dict(B),
    get_dict(party, A, PIdA),
    get_dict(party, B, PIdB),
    PIdA == PIdB.

is_enemy(Actor, Tgt) :-
    get_proxy_ent(Actor, PActor), get_proxy_ent(Tgt, PTgt),
    get_dict(id, PActor, PAId), get_dict(id, PTgt, PTId), PAId \== PTId,
    \+ in_same_party(PActor, PTgt), % Party members are never enemies
    ( is_dict(PActor, plyr) ->
          ( is_dict(PTgt, mob), \+ is_innocent(PTgt)
          ; is_dict(PTgt, plyr)
          ; is_town_npc(PTgt) )
    ; is_dict(PTgt, plyr) ; is_town_npc(PTgt) ).

is_friendly(Actor, Tgt) :-
    get_proxy_ent(Actor, PActor), get_proxy_ent(Tgt, PTgt),
    get_dict(id, PActor, PAId), get_dict(id, PTgt, PTId),
    ( PAId == PTId
    ; in_same_party(PActor, PTgt) % Party members are always friendly
    ; is_dict(PActor, plyr), is_innocent(PTgt), \+ is_dict(PTgt, plyr)
    ; is_dict(PActor, mob), is_dict(PTgt, mob), \+ is_enemy(PActor, PTgt) ).

% Resolved deterministically. Will return 'none' if target query is unfulfillable.
resolve_target(Actor, none, Target) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents),
    (   member(T, Ents),
        is_valid_combat_target(T), get_dict(id, T, TId), get_dict(id, Actor, AId), TId \== AId, entity:is_alive(T),
        is_enemy(Actor, T)
    ->  Target = T
    ;   Target = none
    ), !.
resolve_target(Actor, self, Target) :- !, Target = Actor.
resolve_target(Actor, TgtQuery, Target) :-
    TgtQuery \== none,
    get_dict(room, Actor, Room), world:room_entities(Room, Ents),
    (   member(T, Ents),
        ( get_dict(id, T, TgtQuery) ; get_dict(tag, T, TgtQuery) ),
        entity:is_alive(T)
    ->  Target = T
    ;   Target = none
    ), !.

get_room_targets(Actor, Type, Targets) :-
    get_dict(room, Actor, Room), world:room_entities(Room, Ents),
    include(entity:is_alive, Ents, AliveEnts),
    filter_targets(Actor, AliveEnts, Type, Targets).

filter_targets(Actor, Ents, area, Targets) :-
    get_dict(id, Actor, AId),
    findall(E, (member(E, Ents), is_valid_combat_target(E), get_dict(id, E, EId), EId \== AId), Targets).
filter_targets(Actor, Ents, group_harm, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_enemy(Actor, E)), Targets).
filter_targets(Actor, Ents, group_heal, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_friendly(Actor, E)), Targets).
filter_targets(Actor, Ents, group_buff, Targets) :-
    findall(E, (member(E, Ents), is_valid_combat_target(E), is_friendly(Actor, E)), Targets).

do_pay_bounty(Id, Evts) :-
    ( world:get_entity(Id, Actor) ->
          ( (get_dict(bounty, Actor, B), B > 0) ->
                ( entity:rem_item(Actor, gold, B, A1) ->
                      entity:clear_bounty(A1, FinalA), world:save_db('world_state.json'),
                      clear_local_threats(Id, FinalA), Evts = [bounty_paid(Id, B)]
                ; Evts = [error(insufficient_gold_for_bounty(Id, B))] )
          ; Evts = [error(no_bounty_to_pay(Id))] )
    ; Evts = [error(actor_not_found(Id))] ), !.

clear_local_threats(PId, Player) :-
    get_dict(room, Player, Room), world:room_entities(Room, Ents),
    forall(member(M, Ents), ( ( is_dict(M, mob) -> entity:rem_threat(M, PId, NM), world:put_entity(NM) ; true ) )).
