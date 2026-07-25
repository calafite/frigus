:- module(combat_config, [
              wpn_dmg/2, wpn_trait/2, wpn_crit_mult/2,
              spell_cost/2, spell_cooldown/2, spell_dmg/2,
              spell_type/2, spell_affinity/2, spell_apply_tgt/2, spell_apply_self/2,
              spell_desc/2, spell_summon_tag/2, spell_difficulty/2
                         ]).

:- discontiguous spell_type/2.
:- discontiguous spell_cost/2.
:- discontiguous spell_cooldown/2.
:- discontiguous spell_dmg/2.
:- discontiguous spell_apply_tgt/2.
:- discontiguous spell_apply_self/2.
:- discontiguous spell_affinity/2.
:- discontiguous spell_desc/2.
:- discontiguous spell_summon_tag/2.
:- discontiguous spell_difficulty/2.

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

% Celestial & Legendary Weapons
wpn_dmg(seraphs_blade, [dmg(fire, 22), dmg(slash, 12)]).
wpn_dmg(ancient_runesword, [dmg(slash, 18)]).
wpn_dmg(vampire_fanged_blade, [dmg(pierce, 20)]).
wpn_dmg(necromancer_staff, [dmg(magic, 16)]).

% Innate mob attacks
wpn_dmg(rat, [dmg(pierce, 2)]).
wpn_dmg(wolf, [dmg(slash, 4)]).
wpn_dmg(spectral_wolf, [dmg(magic, 6)]).
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
wpn_dmg(celestial_guardian, [dmg(magic, 15), dmg(slash, 10)]).

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
wpn_trait(seraphs_blade, precision).
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
wpn_crit_mult(seraphs_blade, 2.5).
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
spell_desc(fireball, "A roaring sphere of flame streaks through the air, erupting upon impact.").

spell_type(fireblast, damage).
spell_cost(fireblast, 25).
spell_cooldown(fireblast, 5).
spell_dmg(fireblast, 22).
spell_desc(fireblast, "A violent explosion of white-hot fire blasts forward, leaving scorched earth in its wake.").

spell_type(iceblast, damage).
spell_cost(iceblast, 12).
spell_cooldown(iceblast, 3).
spell_dmg(iceblast, 12).
spell_apply_tgt(iceblast, [frostbite(3, 5)]).
spell_desc(iceblast, "A jagged shard of freezing ice shoots forward, chilling the very air around it.").

spell_type(mend, heal).
spell_cost(mend, 10).
spell_cooldown(mend, 2).
spell_dmg(mend, 30).
spell_desc(mend, "Soft, golden light envelopes the target, knitting wounds and soothing pain.").

spell_type(ignite, damage).
spell_cost(ignite, 10).
spell_cooldown(ignite, 4).
spell_dmg(ignite, 5).
spell_apply_tgt(ignite, [burning(4, 8)]).
spell_desc(ignite, "A sudden spark catches, immediately engulfing the target in searing flames.").

% ==========================================
% CELESTIAL / ANGEL SPELLS
% ==========================================
spell_type(smite, damage).
spell_affinity(smite, [angel, cleric, paladin]).
spell_cost(smite, 35).
spell_cooldown(smite, 6).
spell_dmg(smite, 30).
spell_apply_tgt(smite, [stunned(1, 0), holy_fire(4, 15)]).
spell_desc(smite, "A blinding shaft of holy light crashes down from the heavens.").

spell_type(divine_aegis, buff).
spell_affinity(divine_aegis, [angel, cleric]).
spell_cost(divine_aegis, 50).
spell_cooldown(divine_aegis, 20).
spell_apply_self(divine_aegis, [divine_protection(8, 75)]).
spell_desc(divine_aegis, "Ethereal, glowing wings wrap around the caster, forming an impenetrable barrier of light.").

spell_type(last_judgement, damage).
spell_affinity(last_judgement, [angel]).
spell_cost(last_judgement, 55).
spell_cooldown(last_judgement, 15).
spell_dmg(last_judgement, 40).
spell_apply_tgt(last_judgement, [marked(5, 0)]).
spell_desc(last_judgement, "A booming celestial choir rings out as a terrifying halo of absolute judgment descends.").

spell_type(divine_retribution, damage).
spell_affinity(divine_retribution, [angel]).
spell_cost(divine_retribution, 45).
spell_cooldown(divine_retribution, 8).
spell_dmg(divine_retribution, 25).
spell_apply_tgt(divine_retribution, [stunned(2, 0)]).
spell_desc(divine_retribution, "Golden chains of light burst forth, condemning the unworthy with radiant fury.").

spell_type(mass_heal, group_heal).
spell_affinity(mass_heal, [angel, human, cleric]).
spell_cost(mass_heal, 50).
spell_cooldown(mass_heal, 10).
spell_dmg(mass_heal, 40).
spell_desc(mass_heal, "A warm, radiant aura washes over the battlefield, closing wounds and lifting spirits.").

% ==========================================
% FIRE / INFERNAL / DEMON SPELLS
% ==========================================
spell_type(inferno, area).
spell_affinity(inferno, [demon, warlock]).
spell_cost(inferno, 60).
spell_cooldown(inferno, 12).
spell_dmg(inferno, 30).
spell_apply_tgt(inferno, [burning(6, 12), panicked(2, 0)]).
spell_desc(inferno, "The ground cracks open as columns of hellfire roar upward, turning the area into a blazing furnace.").

spell_type(hellfire, damage).
spell_affinity(hellfire, [demon, warlock]).
spell_cost(hellfire, 45).
spell_cooldown(hellfire, 8).
spell_dmg(hellfire, 35).
spell_apply_tgt(hellfire, [burning(5, 15), soul_rot(5, 10)]).
spell_desc(hellfire, "A stream of dark, demonic fire sears the soul just as intensely as the flesh.").

spell_type(blood_frenzy, buff).
spell_affinity(blood_frenzy, [orc, demon, wolfkin]).
spell_cost(blood_frenzy, 30).
spell_cooldown(blood_frenzy, 15).
spell_apply_self(blood_frenzy, [bloodlust(6, 40)]).
spell_desc(blood_frenzy, "A crimson mist clouds the eyes as an unnatural, bloodthirsty rage takes over.").

spell_type(crimson_oath, buff).
spell_affinity(crimson_oath, [orc, demon, warlock]).
spell_cost(crimson_oath, 20).
spell_cooldown(crimson_oath, 15).
spell_apply_self(crimson_oath, [bloodlust(6, 35), bleeding(6, 3)]).
spell_desc(crimson_oath, "Blood drips from the caster's palms, sealing a dark pact that unleashes furious power.").

% ==========================================
% ELVEN / ARCANE / NATURE SPELLS
% ==========================================
spell_type(moonfire, damage).
spell_affinity(moonfire, [high_elf, wood_elf, dark_elf, druid]).
spell_cost(moonfire, 20).
spell_cooldown(moonfire, 4).
spell_dmg(moonfire, 18).
spell_apply_tgt(moonfire, [holy_fire(3, 10)]).
spell_desc(moonfire, "A silent, silvery beam of concentrated moonlight strikes with piercing intensity.").

spell_type(arcane_barrier, buff).
spell_affinity(arcane_barrier, [high_elf, gnome, mage]).
spell_cost(arcane_barrier, 25).
spell_cooldown(arcane_barrier, 10).
spell_apply_self(arcane_barrier, [magic_barrier(5, 50)]).
spell_desc(arcane_barrier, "Translucent runes swirl into a protective crystalline dome.").

spell_type(barkskin, buff).
spell_affinity(barkskin, [wood_elf, nymph, druid, ranger]).
spell_cost(barkskin, 20).
spell_cooldown(barkskin, 10).
spell_apply_self(barkskin, [fortified(5, 30)]).
spell_desc(barkskin, "Thick, coarse bark rapidly grows over skin, hardening into living armor.").

spell_type(crystal_tomb, cc).
spell_affinity(crystal_tomb, [high_elf, mage]).
spell_cost(crystal_tomb, 40).
spell_cooldown(crystal_tomb, 10).
spell_dmg(crystal_tomb, 8).
spell_apply_tgt(crystal_tomb, [frozen(3, 0), fortified(3, 90)]).
spell_desc(crystal_tomb, "The air shatters as jagged ice crystals rapidly encase the target in a frozen prison.").

spell_type(living_forest, buff).
spell_affinity(living_forest, [wood_elf, nymph, druid]).
spell_cost(living_forest, 35).
spell_cooldown(living_forest, 12).
spell_apply_self(living_forest, [regeneration(6, 10), thornskin(6, 8)]).
spell_desc(living_forest, "Roots burst from the soil, entwining with the caster to mend flesh and punish attackers.").

spell_type(blizzard, area).
spell_affinity(blizzard, [high_elf, dark_elf, mage]).
spell_cost(blizzard, 40).
spell_cooldown(blizzard, 8).
spell_dmg(blizzard, 15).
spell_apply_tgt(blizzard, [frostbite(4, 5)]).
spell_desc(blizzard, "A howling vortex of snow and razored ice rips through the area.").

% ==========================================
% SHADOW / DARK SPELLS
% ==========================================
spell_type(shadow_bolt, damage).
spell_affinity(shadow_bolt, [dark_elf, demon, necromancer, warlock]).
spell_cost(shadow_bolt, 25).
spell_cooldown(shadow_bolt, 4).
spell_dmg(shadow_bolt, 20).
spell_apply_tgt(shadow_bolt, [soul_rot(4, 12)]).
spell_desc(shadow_bolt, "A swirling projectile of pure void tears through the air, whispering with dark malice.").

spell_type(abyssal_curse, damage).
spell_affinity(abyssal_curse, [dark_elf, demon, necromancer, warlock]).
spell_cost(abyssal_curse, 35).
spell_cooldown(abyssal_curse, 8).
spell_dmg(abyssal_curse, 12).
spell_apply_tgt(abyssal_curse, [soul_rot(6, 10), weakened(6, 20)]).
spell_desc(abyssal_curse, "Dark tendrils rise from the shadows, sapping the strength and soul of the victim.").

spell_type(toxic_cloud, area).
spell_affinity(toxic_cloud, [goblin, demon, dark_elf, necromancer]).
spell_cost(toxic_cloud, 30).
spell_cooldown(toxic_cloud, 6).
spell_dmg(toxic_cloud, 5).
spell_apply_tgt(toxic_cloud, [poisoned(5, 8)]).
spell_desc(toxic_cloud, "A sickly, yellow-green fog billows out, choking all who breathe it.").

% ==========================================
% EARTH / LIGHTNING / ARCANE CONTROL
% ==========================================
spell_type(colossus, buff).
spell_affinity(colossus, [dwarf]).
spell_cost(colossus, 40).
spell_cooldown(colossus, 15).
spell_apply_self(colossus, [fortified(6, 40), rooted(6, 0)]).
spell_desc(colossus, "The caster's skin turns to solid stone, anchoring them immovably to the earth.").

spell_type(spellbreaker, cc).
spell_affinity(spellbreaker, [human, high_elf, paladin, mage]).
spell_cost(spellbreaker, 30).
spell_cooldown(spellbreaker, 8).
spell_apply_tgt(spellbreaker, [silenced(3, 0)]).
spell_desc(spellbreaker, "A sharp, dissonant hum shatters the magical weave, silencing spoken words.").

spell_type(chain_lightning, group_harm).
spell_affinity(chain_lightning, [high_elf, human, mage]).
spell_cost(chain_lightning, 45).
spell_cooldown(chain_lightning, 10).
spell_dmg(chain_lightning, 25).
spell_desc(chain_lightning, "A crackling arc of blue lightning leaps violently between enemies.").

spell_type(mass_fortify, group_buff).
spell_affinity(mass_fortify, [dwarf, angel, wood_elf, paladin, cleric]).
spell_cost(mass_fortify, 40).
spell_cooldown(mass_fortify, 15).
spell_apply_tgt(mass_fortify, [fortified(6, 25)]).
spell_desc(mass_fortify, "A heavy, earthen resonance pulses outwards, hardening the resolve and bodies of allies.").

spell_type(choir_of_seraphim, group_buff).
spell_affinity(choir_of_seraphim, [angel, cleric]).
spell_cost(choir_of_seraphim, 60).
spell_cooldown(choir_of_seraphim, 18).
spell_apply_tgt(choir_of_seraphim,
                [divine_protection(5, 40),
                 regeneration(5, 8),
                 blessed(5, 20)]).
spell_desc(choir_of_seraphim, "An angelic choir's song echoes through the realm, blessing allies with divine protection.").

spell_type(heavenly_reckoning, area).
spell_affinity(heavenly_reckoning, [angel, cleric, paladin]).
spell_cost(heavenly_reckoning, 70).
spell_cooldown(heavenly_reckoning, 15).
spell_dmg(heavenly_reckoning, 28).
spell_apply_tgt(heavenly_reckoning,
                [holy_fire(5, 12),
                 blinded(2, 0)]).
spell_desc(heavenly_reckoning, "The sky tears open as devastating pillars of holy fire rain down indiscriminately.").

spell_type(frost_nova, cc).
spell_affinity(frost_nova, [high_elf, human, mage]).
spell_cost(frost_nova, 30).
spell_cooldown(frost_nova, 10).
spell_dmg(frost_nova, 10).
spell_apply_tgt(frost_nova, [frozen(2, 0)]).
spell_desc(frost_nova, "A ring of absolute zero bursts outward, flash-freezing everything in its path.").

spell_type(entangle, cc).
spell_affinity(entangle, [wood_elf, nymph, druid, ranger]).
spell_cost(entangle, 25).
spell_cooldown(entangle, 8).
spell_dmg(entangle, 5).
spell_apply_tgt(entangle, [paralysed(2, 0)]).
spell_desc(entangle, "Thorny vines whip out from the undergrowth, binding the target securely.").

% ==========================================
% SUMMONING SPELLS (CLASS-RESTRICTED)
% ==========================================
spell_type(summon_wolf, summon).
spell_cost(summon_wolf, 30).
spell_cooldown(summon_wolf, 15).
spell_difficulty(summon_wolf, 40).
spell_desc(summon_wolf, "Summons a loyal spectral wolf to fight enemies.").
spell_affinity(summon_wolf, [druid, ranger]).
spell_summon_tag(summon_wolf, spectral_wolf).

spell_type(summon_treant, summon).
spell_cost(summon_treant, 80).
spell_cooldown(summon_treant, 45).
spell_difficulty(summon_treant, 120).
spell_desc(summon_treant, "Awakens an ancient treant to crush your foes.").
spell_affinity(summon_treant, [druid]).
spell_summon_tag(summon_treant, treant).

spell_type(raise_skeleton, summon).
spell_cost(raise_skeleton, 25).
spell_cooldown(raise_skeleton, 12).
spell_difficulty(raise_skeleton, 35).
spell_desc(raise_skeleton, "Raises a fragile skeleton from the earth.").
spell_affinity(raise_skeleton, [necromancer, warlock]).
spell_summon_tag(raise_skeleton, skeleton).

spell_type(raise_lich, summon).
spell_cost(raise_lich, 100).
spell_cooldown(raise_lich, 60).
spell_difficulty(raise_lich, 160).
spell_desc(raise_lich, "Tears a powerful Lich from the underworld.").
spell_affinity(raise_lich, [necromancer]).
spell_summon_tag(raise_lich, lich).

spell_type(summon_imp, summon).
spell_cost(summon_imp, 20).
spell_cooldown(summon_imp, 10).
spell_difficulty(summon_imp, 30).
spell_desc(summon_imp, "Summons a mischievous imp.").
spell_affinity(summon_imp, [warlock]).
spell_summon_tag(summon_imp, imp).

spell_type(summon_demon, summon).
spell_cost(summon_demon, 90).
spell_cooldown(summon_demon, 50).
spell_difficulty(summon_demon, 140).
spell_desc(summon_demon, "Summons a devastating demon brute.").
spell_affinity(summon_demon, [warlock]).
spell_summon_tag(summon_demon, demon_brute).

spell_type(summon_anomaly, summon).
spell_cost(summon_anomaly, 35).
spell_cooldown(summon_anomaly, 20).
spell_difficulty(summon_anomaly, 50).
spell_desc(summon_anomaly, "Conjures an arcane anomaly.").
spell_affinity(summon_anomaly, [mage]).
spell_summon_tag(summon_anomaly, arcane_anomaly).

spell_type(summon_golem, summon).
spell_cost(summon_golem, 85).
spell_cooldown(summon_golem, 55).
spell_difficulty(summon_golem, 130).
spell_desc(summon_golem, "Animates a heavy iron golem.").
spell_affinity(summon_golem, [mage]).
spell_summon_tag(summon_golem, iron_golem).

spell_type(summon_guardian, summon).
spell_cost(summon_guardian, 95).
spell_cooldown(summon_guardian, 60).
spell_difficulty(summon_guardian, 150).
spell_desc(summon_guardian, "Calls forth a Celestial Guardian from the high heavens.").
spell_affinity(summon_guardian, [cleric, paladin, angel]).
spell_summon_tag(summon_guardian, celestial_guardian).

% Fallbacks
spell_apply_tgt(_, []).
spell_apply_self(_, []).
spell_affinity(_, all).
spell_difficulty(_, 0).
spell_summon_tag(_, unknown_summon).
spell_desc(_, "A surge of magical energy fills the air!").
