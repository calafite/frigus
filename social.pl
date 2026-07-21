:- module(social, [
    step_chat/6, step_party/5, step_guild/5,
    party_reward/6, soc/2, soc/3
]).

:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(entity).
:- use_module(world).
:- use_module(prog).

soc(W, S) :- get_dict(social, W, S), !.
soc(_, dict{parties: dict{}, guilds: dict{}, trades: dict{}}).
soc(W, S, W.put(social, S)).

chat_tgts(W, local, Id, Tgts) :-
    world:entity(W, Id, A), room(A, RId),
    world:room_entities(W, RId, Ents),
    findall(E.id, (member(E, Ents), is_dict(E, plyr)), Tgts).
chat_tgts(W, global, _, Tgts) :-
    findall(P.id, member(P, W.plyrs), Tgts).
chat_tgts(W, party, Id, Tgts) :-
    world:entity(W, Id, A), get_dict(party, A, PId), PId \== none,
    soc(W, S), get_dict(PId, S.parties, P), Tgts = P.members.
chat_tgts(W, guild, Id, Tgts) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G), Tgts = G.members.
chat_tgts(_, whisper(Tgt), _, [Tgt]).

step_chat(W, Id, Chan, Msg, W, [chat(Chan, Id, Msg, Tgts)]) :- chat_tgts(W, Chan, Id, Tgts), !.
step_chat(W, _, _, _, W, []).

step_party(W, Id, create, NW, [party_created(Id, PId)]) :-
    world:entity(W, Id, A), \+ get_dict(party, A, _),
    random_between(10000, 99999, R), atomic_list_concat([party_, R], PId),
    soc(W, S), P = dict{id: PId, ldr: Id, members: [Id]},
    Ps = S.parties.put(PId, P), soc(W, S.put(parties, Ps), W1),
    world:update(W1, A.put(party, PId), NW).

step_party(W, Id, invite(Tgt), W, [party_inv(Id, Tgt, PId)]) :-
    world:entity(W, Id, A), get_dict(party, A, PId), PId \== none,
    soc(W, S), get_dict(PId, S.parties, P), P.ldr == Id.

step_party(W, Id, join(PId), NW, [party_joined(Id, PId)]) :-
    world:entity(W, Id, A), \+ get_dict(party, A, _),
    soc(W, S), get_dict(PId, S.parties, P),
    NP = P.put(members, [Id|P.members]),
    Ps = S.parties.put(PId, NP), soc(W, S.put(parties, Ps), W1),
    world:update(W1, A.put(party, PId), NW).

step_party(W, Id, leave, NW, [party_left(Id)]) :-
    world:entity(W, Id, A), get_dict(party, A, PId), PId \== none,
    soc(W, S), get_dict(PId, S.parties, P),
    select(Id, P.members, NMs),
    ( NMs == [] -> del_dict(PId, S.parties, _, NPs)
    ; P.ldr == Id -> NMs = [NLdr|_], NPs = S.parties.put(PId, P.put(ldr, NLdr).put(members, NMs))
    ; NPs = S.parties.put(PId, P.put(members, NMs)) ),
    soc(W, S.put(parties, NPs), W1),
    world:update(W1, A.put(party, none), NW).

step_party(W, Id, kick(Tgt), NW, [party_kicked(Tgt)]) :-
    world:entity(W, Id, A), get_dict(party, A, PId), PId \== none,
    soc(W, S), get_dict(PId, S.parties, P), P.ldr == Id,
    select(Tgt, P.members, NMs),
    NPs = S.parties.put(PId, P.put(members, NMs)),
    soc(W, S.put(parties, NPs), W1),
    world:entity(W1, Tgt, T), world:update(W1, T.put(party, none), NW).

party_reward(W, PId, RId, Base, NW, Evts) :-
    soc(W, S), get_dict(PId, S.parties, P),
    findall(M, (member(M, P.members), world:entity(W, M, E), room(E, RId)), Valid),
    length(Valid, L), ( L > 0 -> Xp is ceil(Base / L) ; Xp = Base ),
    dist_xp(W, Valid, Xp, NW, Evts).

dist_xp(W, [], _, W, []).
dist_xp(W, [H|T], Xp, NW, [xp(H, Xp)|Evts]) :-
    world:entity(W, H, A), prog:add_xp(A, Xp, NA, PEvts),
    world:update(W, NA, W1), dist_xp(W1, T, Xp, NW, REvts),
    append(PEvts, REvts, Evts).

step_guild(W, Id, create(Name), NW, [guild_created(Id, GId)]) :-
    world:entity(W, Id, A), \+ get_dict(guild, A, _),
    random_between(10000, 99999, R), atomic_list_concat([guild_, R], GId),
    soc(W, S), G = dict{id: GId, name: Name, master: Id, officers: [], members: [Id], stash: []},
    Gs = S.guilds.put(GId, G), soc(W, S.put(guilds, Gs), W1),
    world:update(W1, A.put(guild, GId), NW).

step_guild(W, Id, invite(Tgt), W, [guild_inv(Id, Tgt, GId)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G),
    ( G.master == Id ; member(Id, G.officers) ).

step_guild(W, Id, join(GId), NW, [guild_joined(Id, GId)]) :-
    world:entity(W, Id, A), \+ get_dict(guild, A, _),
    soc(W, S), get_dict(GId, S.guilds, G),
    NG = G.put(members, [Id|G.members]),
    Gs = S.guilds.put(GId, NG), soc(W, S.put(guilds, Gs), W1),
    world:update(W1, A.put(guild, GId), NW).

step_guild(W, Id, leave, NW, [guild_left(Id)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G), G.master \== Id,
    select(Id, G.members, NMs),
    ( select(Id, G.officers, NOs) -> true ; NOs = G.officers ),
    NGs = S.guilds.put(GId, G.put(members, NMs).put(officers, NOs)),
    soc(W, S.put(guilds, NGs), W1),
    world:update(W1, A.put(guild, none), NW).

step_guild(W, Id, kick(Tgt), NW, [guild_kicked(Tgt)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G),
    ( G.master == Id ; member(Id, G.officers) ), Tgt \== G.master,
    select(Tgt, G.members, NMs),
    ( select(Tgt, G.officers, NOs) -> true ; NOs = G.officers ),
    NGs = S.guilds.put(GId, G.put(members, NMs).put(officers, NOs)),
    soc(W, S.put(guilds, NGs), W1),
    world:entity(W1, Tgt, T), world:update(W1, T.put(guild, none), NW).

step_guild(W, Id, promote(Tgt), NW, [guild_promoted(Tgt)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G), G.master == Id,
    member(Tgt, G.members), \+ member(Tgt, G.officers),
    NGs = S.guilds.put(GId, G.put(officers, [Tgt|G.officers])),
    soc(W, S.put(guilds, NGs), NW).

step_guild(W, Id, stash_put(Tag, Q), NW, [guild_stash_put(Id, Tag, Q)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    inv(A, Inv), inv_rem(Inv, Tag, Q, NInv), A1 = A.put(inv, NInv),
    soc(W, S), get_dict(GId, S.guilds, G),
    inv_add(G.stash, Tag, Q, NStash),
    NGs = S.guilds.put(GId, G.put(stash, NStash)),
    soc(W, S.put(guilds, NGs), W1),
    world:update(W1, A1, NW).

step_guild(W, Id, stash_take(Tag, Q), NW, [guild_stash_take(Id, Tag, Q)]) :-
    world:entity(W, Id, A), get_dict(guild, A, GId), GId \== none,
    soc(W, S), get_dict(GId, S.guilds, G),
    inv_rem(G.stash, Tag, Q, NStash),
    inv(A, Inv), inv_add(Inv, Tag, Q, NInv), A1 = A.put(inv, NInv),
    NGs = S.guilds.put(GId, G.put(stash, NStash)),
    soc(W, S.put(guilds, NGs), W1),
    world:update(W1, A1, NW).
