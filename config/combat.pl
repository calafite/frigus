:- module(combat_config, [
    wpn_dmg/2, wpn_trait/2, wpn_crit_mult/2,
    spell_cost/2, spell_cooldown/2, spell_dmg/2,
    spell_type/2, spell_affinity/2, spell_apply_tgt/2, spell_apply_self/2
]).

% ==========================================
% WEAPON CONFIGURATION
% ==========================================
wpn_dmg(fists, [dmg(blunt, 3)]).
wpn_dmg(dagger, [dmg(pierce, 5)]).
wpn_dmg(shortsword, [dmg(slash, 7)]).
wpn_dmg(sword, [dmg(slash, 8)]).
wpn_dmg(greatsword, [dmg(slash, 12)]).
wpn_dmg(battleaxe, [dmg(slash, 14)]).
wpn_dmg(shortbow, [dmg(pierce, 7)]).
wpn_dmg(staff, [dmg(blunt, 5)]).
wpn_dmg(iron_sword, [dmg(slash, 10)]).

wpn_dmg(rat, [dmg(pierce, 2)]).
wpn_dmg(wolf, [dmg(slash, 4)]).
wpn_dmg(goblin, [dmg(slash, 5)]).
wpn_dmg(orc, [dmg(blunt, 8)]).
wpn_dmg(dragon, [dmg(fire, 25)]).

wpn_trait(sword, reliable).
wpn_trait(iron_sword, reliable).
wpn_trait(shortsword, reliable).
wpn_trait(dagger, flurry).
wpn_trait(battleaxe, massacre).
wpn_trait(greatsword, massacre).
wpn_trait(shortbow, precision).
wpn_trait(staff, catalyst).
wpn_trait(_, standard).

wpn_crit_mult(battleaxe, 2.5).
wpn_crit_mult(greatsword, 2.5).
wpn_crit_mult(dagger, 1.8).
wpn_crit_mult(_, 2.0).

% ==========================================
% SPELL CONFIGURATION
% ==========================================
% spell_type: damage, heal, buff, debuff, cc

% --- General Spells (Anyone can cast if they have the MP) ---
spell_type(fireball, damage).
spell_cost(fireball, 15).
spell_cooldown(fireball, 3).
spell_dmg(fireball, 15).

spell_type(fireblast, damage).
spell_cost(fireblast, 25).
spell_cooldown(fireblast, 5).
spell_dmg(fireblast, 22).

spell_type(iceblast, damage).
spell_cost(iceblast, 12).
spell_cooldown(iceblast, 3).
spell_dmg(iceblast, 12).
spell_apply_tgt(iceblast, [frostbite(3, 5)]). % Frostbite for 3 ticks, 5 dmg

spell_type(mend, heal).
spell_cost(mend, 10).
spell_cooldown(mend, 2).

spell_type(ignite, damage).
spell_cost(ignite, 10).
spell_cooldown(ignite, 4).
spell_dmg(ignite, 5).
spell_apply_tgt(ignite, [burning(4, 8)]).

% --- Elven Magic ---
spell_affinity(moonfire, [high_elf, wood_elf, dark_elf]).
spell_type(moonfire, damage).
spell_cost(moonfire, 20).
spell_cooldown(moonfire, 4).
spell_dmg(moonfire, 18).
spell_apply_tgt(moonfire, [holy_fire(3, 10)]).

spell_affinity(arcane_barrier, [high_elf, gnome]).
spell_type(arcane_barrier, buff).
spell_cost(arcane_barrier, 25).
spell_cooldown(arcane_barrier, 10).
spell_apply_self(arcane_barrier, [magic_barrier(5, 50)]). % 50% magic dmg reduction for 5 ticks

spell_affinity(barkskin, [wood_elf, nymph]).
spell_type(barkskin, buff).
spell_cost(barkskin, 20).
spell_cooldown(barkskin, 10).
spell_apply_self(barkskin, [fortified(5, 30)]). % 30% all dmg reduction

% --- Dark / Demonic Magic ---
spell_affinity(shadow_bolt, [dark_elf, demon]).
spell_type(shadow_bolt, damage).
spell_cost(shadow_bolt, 25).
spell_cooldown(shadow_bolt, 4).
spell_dmg(shadow_bolt, 20).
spell_apply_tgt(shadow_bolt, [soul_rot(4, 12)]).

spell_affinity(hellfire, [demon]).
spell_type(hellfire, damage).
spell_cost(hellfire, 45).
spell_cooldown(hellfire, 8).
spell_dmg(hellfire, 35).
spell_apply_tgt(hellfire, [burning(5, 15), soul_rot(5, 10)]).

spell_affinity(blood_frenzy, [orc, demon, wolfkin]).
spell_type(blood_frenzy, buff).
spell_cost(blood_frenzy, 30).
spell_cooldown(blood_frenzy, 15).
spell_apply_self(blood_frenzy, [bloodlust(6, 40)]). % +40% physical dmg output

% --- Celestial Magic ---
spell_affinity(smite, [angel]).
spell_type(smite, damage).
spell_cost(smite, 35).
spell_cooldown(smite, 6).
spell_dmg(smite, 30).
spell_apply_tgt(smite, [stunned(1, 0), holy_fire(4, 15)]). % Stuns for 1 tick

spell_affinity(divine_aegis, [angel]).
spell_type(divine_aegis, buff).
spell_cost(divine_aegis, 50).
spell_cooldown(divine_aegis, 20).
spell_apply_self(divine_aegis, [divine_protection(8, 75)]). % 75% dmg reduction

% --- CC / Disables ---
spell_affinity(frost_nova, [high_elf, human]).
spell_type(frost_nova, cc).
spell_cost(frost_nova, 30).
spell_cooldown(frost_nova, 10).
spell_dmg(frost_nova, 10).
spell_apply_tgt(frost_nova, [frozen(2, 0)]). % Frozen prevents action for 2 ticks

spell_affinity(entangle, [wood_elf, nymph]).
spell_type(entangle, cc).
spell_cost(entangle, 25).
spell_cooldown(entangle, 8).
spell_dmg(entangle, 5).
spell_apply_tgt(entangle, [paralysed(2, 0)]).

spell_apply_tgt(_, []).
spell_apply_self(_, []).
spell_affinity(_, all).
