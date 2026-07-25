:- module(party, [do_party/4]).

:- use_module('../core/world').
:- use_module('../core/entity').
:- use_module('combat').
:- use_module(library(lists)).

get_player_name(Actor, Name) :-
    ( get_dict(name, Actor, Name) -> true ; get_dict(id, Actor, Name) ).

do_party(Id, _Action, _Target, [error(actor_not_found(Id))]) :- \+ world:get_entity(Id, _), !.

% CREATE PARTY
do_party(Id, new, TargetName, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, _) ->
        Evts = [error(already_in_party)]
    ; TargetName == none ->
        Evts = [error(party_name_required)]
    ;
        world:gen_id(party, PId),
        Party = party{id: PId, name: TargetName, leader: Id, members: [Id]},
        world:put_party(Party),
        NActor = Actor.put(party, PId),
        world:put_entity(NActor),
        world:save_db('world_state.json'),
        get_player_name(NActor, Name),
        Evts = [party_created(Name, TargetName)]
    ).

% LIST PARTY
do_party(Id, list, _Target, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, PId) ->
        ( world:get_party(PId, Party) ->
            get_dict(name, Party, PName),
            get_dict(leader, Party, LeaderId),
            get_dict(members, Party, MembersList),
            findall(MName, (member(MId, MembersList), world:get_entity(MId, MEnt), get_player_name(MEnt, MName)), NamesList),
            Evts = [party_info(PName, LeaderId, NamesList)]
        ;
            Evts = [error(party_not_found)]
        )
    ;
        Evts = [error(not_in_party)]
    ).

% INVITE TO PARTY (Must be in same room)
do_party(Id, invite, TargetName, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, PId) ->
        ( world:get_party(PId, Party) ->
            get_dict(leader, Party, LeaderId),
            ( LeaderId == Id ->
                get_dict(room, Actor, RoomId),
                world:room_entities(RoomId, Ents),
                ( member(TargetEnt, Ents), is_dict(TargetEnt, plyr), get_player_name(TargetEnt, TargetName) ->
                    get_dict(id, TargetEnt, TargetId),
                    ( get_dict(party, TargetEnt, _) ->
                        Evts = [error(target_already_in_party(TargetName))]
                    ;
                        world:add_party_invite(TargetId, PId),
                        get_dict(name, Party, PartyName),
                        get_player_name(Actor, ActorName),
                        % It's broadcasted to the room so the target sees it.
                        Evts = [party_invite_sent(ActorName, TargetName, PartyName)]
                    )
                ;
                    Evts = [error(player_not_found(TargetName))]
                )
            ;
                Evts = [error(not_party_leader)]
            )
        ;
            Evts = [error(party_not_found)]
        )
    ;
        Evts = [error(not_in_party)]
    ).

% ACCEPT INVITE
do_party(Id, accept, _TargetName, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, _) ->
        Evts = [error(already_in_party)]
    ;
        ( world:get_party_invite(Id, PId) ->
            ( world:get_party(PId, Party) ->
                get_dict(members, Party, Members),
                NMembers = [Id | Members],
                NParty = Party.put(members, NMembers),
                world:put_party(NParty),
                NActor = Actor.put(party, PId),
                world:put_entity(NActor),
                world:rem_party_invite(Id, PId),
                world:save_db('world_state.json'),
                get_dict(name, Party, PName),
                get_player_name(Actor, ActorName),
                % Broadcast to room
                Evts = [party_joined(ActorName, PName)]
            ;
                world:rem_party_invite(Id, PId),
                Evts = [error(party_not_found)]
            )
        ;
            Evts = [error(no_pending_invite)]
        )
    ).

% LEAVE PARTY
do_party(Id, leave, _TargetName, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, PId) ->
        ( world:get_party(PId, Party) ->
            get_dict(leader, Party, LeaderId),
            get_player_name(Actor, ActorName),
            get_dict(name, Party, PName),
            ( LeaderId == Id ->
                get_dict(members, Party, Members),
                forall(member(MId, Members), (
                    world:get_entity(MId, MEnt),
                    del_dict(party, MEnt, _, NMEnt),
                    world:put_entity(NMEnt)
                )),
                world:del_party(PId),
                world:save_db('world_state.json'),
                Evts = [party_disbanded(PName)]
            ;
                % Normal member leaving
                get_dict(members, Party, Members),
                delete(Members, Id, NMembers),
                NParty = Party.put(members, NMembers),
                world:put_party(NParty),
                del_dict(party, Actor, _, NActor),
                world:put_entity(NActor),
                world:save_db('world_state.json'),
                Evts = [party_left(ActorName, PName)]
            )
        ;
            del_dict(party, Actor, _, NActor),
            world:put_entity(NActor),
            Evts = [error(party_not_found)]
        )
    ;
        Evts = [error(not_in_party)]
    ).

% KICK FROM PARTY
do_party(Id, kick, TargetName, Evts) :-
    world:get_entity(Id, Actor),
    ( get_dict(party, Actor, PId) ->
        ( world:get_party(PId, Party) ->
            get_dict(leader, Party, LeaderId),
            ( LeaderId == Id ->
                get_dict(members, Party, Members),
                ( member(MId, Members), world:get_entity(MId, TgtEnt), get_player_name(TgtEnt, TargetName) ->
                    ( MId == Id ->
                        Evts = [error(cannot_kick_self)]
                    ;
                        delete(Members, MId, NMembers),
                        NParty = Party.put(members, NMembers),
                        world:put_party(NParty),
                        del_dict(party, TgtEnt, _, NTgtEnt),
                        world:put_entity(NTgtEnt),
                        world:save_db('world_state.json'),
                        get_dict(name, Party, PName),
                        Evts = [party_kicked(TargetName, PName)]
                    )
                ;
                    Evts = [error(member_not_found(TargetName))]
                )
            ;
                Evts = [error(not_party_leader)]
            )
        ;
            Evts = [error(party_not_found)]
        )
    ;
        Evts = [error(not_in_party)]
    ).

do_party(_, _, _, [error(invalid_party_command)]).
