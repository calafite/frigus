:- module(combat_config, [
    wpn_dmg/2, wpn_trait/2, wpn_crit_mult/2,
    spell_cost/2, spell_cooldown/2, spell_dmg/2,
    spell_type/2, spell_affinity/2, spell_apply_tgt/2, spell_apply_self/2
]).

:- discontiguous spell_type/2.
:- discontiguous spell_cost/2.
:- discontiguous spell_cooldown/2.
:- discontiguous spell_dmg/2.
:- discontiguous spell_apply_tgt/2.
:- discontiguous spell_apply_self/2.
:- discontiguous spell_affinity/2.

% ==========================================
% WEAPON & INNATE MOB DAMAGE
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

% Unique Boss Weapons
wpn_dmg(ancient_runesword, [dmg(slash, 18)]).
wpn_dmg(vampire_fanged_blade, [dmg(pierce, 20)]).
wpn_dmg(necromancer_staff, [dmg(magic, 16)]).

% Innate mob attacks
wpn_dmg(rat, [dmg(pierce, 2)]).
wpn_dmg(wolf, [dmg(slash, 4)]).
wpn_dmg(goblin, [dmg(slash, 5)]).
wpn_dmg(orc, [dmg(blunt, 8)]).
wpn_dmg(dragon, [dmg(fire, 25)]).
wpn_dmg(bear, [dmg(slash, 8)]).
wpn_dmg(viper, [dmg(pierce, 5)]).
wpn_dmg(giant_spider, [dmg(pierce, 6)]).
wpn_dmg(dire_wolf, [dmg(slash, 7)]).
wpn_dmg(skeleton, [dmg(slash, 5)]).
wpn_dmg(zombie, [dmg(blunt, 6)]).
wpn_dmg(wraith, [dmg(magic, 8)]).
wpn_dmg(lich, [dmg(magic, 18)]).
wpn_dmg(hobgoblin, [dmg(blunt, 8)]).
wpn_dmg(bandit, [dmg(slash, 7)]).
wpn_dmg(imp, [dmg(fire, 5)]).
wpn_dmg(hellhound, [dmg(fire, 8)]).
wpn_dmg(demon_brute, [dmg(blunt, 12)]).
wpn_dmg(salamander, [dmg(fire, 7)]).
wpn_dmg(rock_worm, [dmg(blunt, 9)]).
wpn_dmg(gargoyle, [dmg(slash, 8)]).
wpn_dmg(iron_golem, [dmg(blunt, 14)]).
wpn_dmg(arcane_anomaly, [dmg(magic, 9)]).
wpn_dmg(treant, [dmg(blunt, 11)]).

% Structure Anomaly Boss Attacks
wpn_dmg(elder_dragon, [dmg(fire, 35)]).
wpn_dmg(swamp_hag, [dmg(magic, 20)]).
wpn_dmg(ruin_golem, [dmg(blunt, 30)]).
wpn_dmg(ancient_treant_lord, [dmg(blunt, 25)]).
wpn_dmg(vampire_lord, [dmg(pierce, 28)]).
wpn_dmg(void_walker, [dmg(magic, 30)]).
wpn_dmg(arch_necromancer, [dmg(magic, 32)]).

wpn_trait(sword, reliable).
wpn_trait(iron_sword, reliable).
wpn_trait(shortsword, reliable).
wpn_trait(ancient_runesword, reliable).
wpn_trait(vampire_fanged_blade, flurry).
wpn_trait(necromancer_staff, catalyst).
wpn_trait(dagger, flurry).
wpn_trait(battleaxe, massacre).
wpn_trait(greatsword, massacre).
wpn_trait(shortbow, precision).
wpn_trait(staff, catalyst).
wpn_trait(_, standard).

wpn_crit_mult(battleaxe, 2.5).
wpn_crit_mult(greatsword, 2.5).
wpn_crit_mult(dagger, 1.8).
wpn_crit_mult(vampire_fanged_blade, 2.2).
wpn_crit_mult(_, 2.0).

% ==========================================
% GENERAL / BASE SPELLS
% ==========================================
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
spell_apply_tgt(iceblast, [frostbite(3, 5)]).

spell_type(mend, heal).
spell_cost(mend, 10).
spell_cooldown(mend, 2).
spell_dmg(mend, 30).

spell_type(ignite, damage).
spell_cost(ignite, 10).
spell_cooldown(ignite, 4).
spell_dmg(ignite, 5).
spell_apply_tgt(ignite, [burning(4, 8)]).

% ==========================================
% CELESTIAL / ANGEL SPELLS
% ==========================================
spell_type(smite, damage).
spell_affinity(smite, [angel]).
spell_cost(smite, 35).
spell_cooldown(smite, 6).
spell_dmg(smite, 30).
spell_apply_tgt(smite, [stunned(1, 0), holy_fire(4, 15)]).

spell_type(divine_aegis, buff).
spell_affinity(divine_aegis, [angel]).
spell_cost(divine_aegis, 50).
spell_cooldown(divine_aegis, 20).
spell_apply_self(divine_aegis, [divine_protection(8, 75)]).

spell_type(last_judgement, damage).
spell_affinity(last_judgement, [angel]).
spell_cost(last_judgement, 55).
spell_cooldown(last_judgement, 15).
spell_dmg(last_judgement, 40).
spell_apply_tgt(last_judgement, [marked(5, 0)]).

spell_type(divine_retribution, damage).
spell_affinity(divine_retribution, [angel]).
spell_cost(divine_retribution, 45).
spell_cooldown(divine_retribution, 8).
spell_dmg(divine_retribution, 25).
spell_apply_tgt(divine_retribution, [stunned(2, 0)]).

spell_type(mass_heal, group_heal).
spell_affinity(mass_heal, [angel, human]).
spell_cost(mass_heal, 50).
spell_cooldown(mass_heal, 10).
spell_dmg(mass_heal, 40).

% ==========================================
% FIRE / INFERNAL / DEMON SPELLS
% ==========================================
spell_type(inferno, area).
spell_affinity(inferno, [demon]).
spell_cost(inferno, 60).
spell_cooldown(inferno, 12).
spell_dmg(inferno, 30).
spell_apply_tgt(inferno, [burning(6, 12), panicked(2, 0)]).

spell_type(hellfire, damage).
spell_affinity(hellfire, [demon]).
spell_cost(hellfire, 45).
spell_cooldown(hellfire, 8).
spell_dmg(hellfire, 35).
spell_apply_tgt(hellfire, [burning(5, 15), soul_rot(5, 10)]).

spell_type(blood_frenzy, buff).
spell_affinity(blood_frenzy, [orc, demon, wolfkin]).
spell_cost(blood_frenzy, 30).
spell_cooldown(blood_frenzy, 15).
spell_apply_self(blood_frenzy, [bloodlust(6, 40)]).

spell_type(crimson_oath, buff).
spell_affinity(crimson_oath, [orc, demon]).
spell_cost(crimson_oath, 20).
spell_cooldown(crimson_oath, 15).
spell_apply_self(crimson_oath, [bloodlust(6, 35), bleeding(6, 3)]).

% ==========================================
% ELVEN / ARCANE / NATURE SPELLS
% ==========================================
spell_type(moonfire, damage).
spell_affinity(moonfire, [high_elf, wood_elf, dark_elf]).
spell_cost(moonfire, 20).
spell_cooldown(moonfire, 4).
spell_dmg(moonfire, 18).
spell_apply_tgt(moonfire, [holy_fire(3, 10)]).

spell_type(arcane_barrier, buff).
spell_affinity(arcane_barrier, [high_elf, gnome]).
spell_cost(arcane_barrier, 25).
spell_cooldown(arcane_barrier, 10).
spell_apply_self(arcane_barrier, [magic_barrier(5, 50)]).

spell_type(barkskin, buff).
spell_affinity(barkskin, [wood_elf, nymph]).
spell_cost(barkskin, 20).
spell_cooldown(barkskin, 10).
spell_apply_self(barkskin, [fortified(5, 30)]).

spell_type(crystal_tomb, cc).
spell_affinity(crystal_tomb, [high_elf]).
spell_cost(crystal_tomb, 40).
spell_cooldown(crystal_tomb, 10).
spell_dmg(crystal_tomb, 8).
spell_apply_tgt(crystal_tomb, [frozen(3, 0), fortified(3, 90)]).

spell_type(living_forest, buff).
spell_affinity(living_forest, [wood_elf, nymph]).
spell_cost(living_forest, 35).
spell_cooldown(living_forest, 12).
spell_apply_self(living_forest, [regeneration(6, 10), thornskin(6, 8)]).

spell_type(blizzard, area).
spell_affinity(blizzard, [high_elf, dark_elf]).
spell_cost(blizzard, 40).
spell_cooldown(blizzard, 8).
spell_dmg(blizzard, 15).
spell_apply_tgt(blizzard, [frostbite(4, 5)]).

% ==========================================
% SHADOW / DARK SPELLS
% ==========================================
spell_type(shadow_bolt, damage).
spell_affinity(shadow_bolt, [dark_elf, demon]).
spell_cost(shadow_bolt, 25).
spell_cooldown(shadow_bolt, 4).
spell_dmg(shadow_bolt, 20).
spell_apply_tgt(shadow_bolt, [soul_rot(4, 12)]).

spell_type(abyssal_curse, damage).
spell_affinity(abyssal_curse, [dark_elf, demon]).
spell_cost(abyssal_curse, 35).
spell_cooldown(abyssal_curse, 8).
spell_dmg(abyssal_curse, 12).
spell_apply_tgt(abyssal_curse, [soul_rot(6, 10), weakened(6, 20)]).

spell_type(toxic_cloud, area).
spell_affinity(toxic_cloud, [goblin, demon, dark_elf]).
spell_cost(toxic_cloud, 30).
spell_cooldown(toxic_cloud, 6).
spell_dmg(toxic_cloud, 5).
spell_apply_tgt(toxic_cloud, [poisoned(5, 8)]).

% ==========================================
% EARTH / LIGHTNING / ARCANE CONTROL
% ==========================================
spell_type(colossus, buff).
spell_affinity(colossus, [dwarf]).
spell_cost(colossus, 40).
spell_cooldown(colossus, 15).
spell_apply_self(colossus, [fortified(6, 40), rooted(6, 0)]).

spell_type(spellbreaker, cc).
spell_affinity(spellbreaker, [human, high_elf]).
spell_cost(spellbreaker, 30).
spell_cooldown(spellbreaker, 8).
spell_apply_tgt(spellbreaker, [silenced(3, 0)]).

spell_type(chain_lightning, group_harm).
spell_affinity(chain_lightning, [high_elf, human]).
spell_cost(chain_lightning, 45).
spell_cooldown(chain_lightning, 10).
spell_dmg(chain_lightning, 25).

spell_type(mass_fortify, group_buff).
spell_affinity(mass_fortify, [dwarf, angel, wood_elf]).
spell_cost(mass_fortify, 40).
spell_cooldown(mass_fortify, 15).
spell_apply_tgt(mass_fortify, [fortified(6, 25)]).

spell_type(choir_of_seraphim, group_buff).
spell_affinity(choir_of_seraphim, [angel]).
spell_cost(choir_of_seraphim, 60).
spell_cooldown(choir_of_seraphim, 18).
spell_apply_tgt(choir_of_seraphim,
    [divine_protection(5, 40),
     regeneration(5, 8),
     blessed(5, 20)]).

spell_type(heavenly_reckoning, area).
spell_affinity(heavenly_reckoning, [angel]).
spell_cost(heavenly_reckoning, 70).
spell_cooldown(heavenly_reckoning, 15).
spell_dmg(heavenly_reckoning, 28).
spell_apply_tgt(heavenly_reckoning,
    [holy_fire(5, 12),
     blinded(2, 0)]).

spell_type(frost_nova, cc).
spell_affinity(frost_nova, [high_elf, human]).
spell_cost(frost_nova, 30).
spell_cooldown(frost_nova, 10).
spell_dmg(frost_nova, 10).
spell_apply_tgt(frost_nova, [frozen(2, 0)]).

spell_type(entangle, cc).
spell_affinity(entangle, [wood_elf, nymph]).
spell_cost(entangle, 25).
spell_cooldown(entangle, 8).
spell_dmg(entangle, 5).
spell_apply_tgt(entangle, [paralysed(2, 0)]).

% Fallbacks
spell_apply_tgt(_, []).
spell_apply_self(_, []).
spell_affinity(_, all).
