:- module(combat_config, [
    wpn_dmg/2, spell_cost/2, spell_cooldown/2, spell_dmg/2
]).

wpn_dmg(fists, [dmg(blunt, 3)]).
wpn_dmg(staff, [dmg(blunt, 5)]).
wpn_dmg(dagger, [dmg(pierce, 5)]).
wpn_dmg(sword, [dmg(slash, 8)]).
wpn_dmg(shortbow, [dmg(pierce, 7)]).
wpn_dmg(iron_sword, [dmg(slash, 10)]).

wpn_dmg(rat, [dmg(pierce, 2)]).
wpn_dmg(wolf, [dmg(slash, 4)]).
wpn_dmg(goblin, [dmg(slash, 5)]).
wpn_dmg(orc, [dmg(blunt, 8)]).
wpn_dmg(dragon, [dmg(fire, 25)]).

spell_cost(fireball, 15).
spell_cost(fireblast, 25).
spell_cost(iceblast, 12).
spell_cost(mend, 10).

spell_cooldown(fireball, 3).
spell_cooldown(fireblast, 5).
spell_cooldown(iceblast, 3).
spell_cooldown(mend, 2).

spell_dmg(fireball, 15).
spell_dmg(fireblast, 22).
spell_dmg(iceblast, 12).
