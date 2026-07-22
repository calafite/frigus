:- module(cfg_magic, [
    cost/2, cooldown/2, spell_nature/2, req_race/2,
    aoe/1, friendly_fire_enabled/1, summon/2, is_utility_spell/1
]).

cost(fireball, 15).
cost(iceblast, 12).
cost(bash, 5).
cost(mend, 10).
cost(rejuvenate, 20).
cost(raise_dead, 30).
cost(summon_demon, 50).
cost(summon_elemental, 40).
cost(haste, 15).
cost(stoneskin, 20).
cost(meteor_storm, 60).
cost(judgment, 45).
cost(fireblast, 25).
cost(holy_light, 18).
cost(earthquake, 50).
cost(chain_lightning, 35).
cost(bloodline_curse, 40).
cost(fire_breath, 0).

cost(blink, 15).
cost(teleport, 30).
cost(invisibility, 20).
cost(light_spell, 10).
cost(dispel, 15).
cost(identify_spell, 20).
cost(remove_curse, 25).
cost(banish, 40).
cost(planar_gate, 50).
cost(gender_shift, 20).
cost(curse_word, 50).

cooldown(fireball, 3).
cooldown(iceblast, 3).
cooldown(bash, 2).
cooldown(mend, 2).
cooldown(rejuvenate, 5).
cooldown(raise_dead, 10).
cooldown(summon_demon, 20).
cooldown(summon_elemental, 15).
cooldown(haste, 8).
cooldown(stoneskin, 10).
cooldown(meteor_storm, 12).
cooldown(judgment, 8).
cooldown(fireblast, 5).
cooldown(holy_light, 4).
cooldown(earthquake, 10).
cooldown(chain_lightning, 6).
cooldown(bloodline_curse, 15).
cooldown(fire_breath, 4).

cooldown(blink, 5).
cooldown(teleport, 10).
cooldown(invisibility, 12).
cooldown(light_spell, 5).
cooldown(dispel, 4).
cooldown(identify_spell, 5).
cooldown(remove_curse, 8).
cooldown(banish, 15).
cooldown(planar_gate, 30).
cooldown(gender_shift, 15).
cooldown(curse_word, 30).

spell_nature(fireball, fire).
spell_nature(iceblast, ice).
spell_nature(mend, magic).
spell_nature(rejuvenate, nature).
spell_nature(raise_dead, dark).
spell_nature(summon_demon, dark).
spell_nature(summon_elemental, magic).
spell_nature(haste, magic).
spell_nature(stoneskin, earth).
spell_nature(meteor_storm, fire).
spell_nature(judgment, holy).
spell_nature(fireblast, fire).
spell_nature(holy_light, holy).
spell_nature(earthquake, earth).
spell_nature(chain_lightning, lightning).
spell_nature(bloodline_curse, dark).
spell_nature(bash, blunt).
spell_nature(fire_breath, fire).

spell_nature(blink, utility).
spell_nature(teleport, utility).
spell_nature(invisibility, utility).
spell_nature(light_spell, utility).
spell_nature(dispel, utility).
spell_nature(identify_spell, utility).
spell_nature(remove_curse, utility).
spell_nature(banish, utility).
spell_nature(planar_gate, utility).
spell_nature(gender_shift, utility).
spell_nature(curse_word, utility).

is_utility_spell(Sp) :- spell_nature(Sp, utility).

req_race(meteor_storm, demigod).
req_race(earthquake, demigod).
req_race(judgment, angel).
req_race(holy_light, angel).
req_race(bloodline_curse, demon).
req_race(summon_demon, demon).
req_race(banish, angel).
req_race(planar_gate, demigod).
req_race(curse_word, demigod).
req_race(_, none).

aoe(meteor_storm).
aoe(earthquake).
aoe(chain_lightning).
aoe(fire_breath).

friendly_fire_enabled(meteor_storm).
friendly_fire_enabled(earthquake).
friendly_fire_enabled(fire_breath).

summon(raise_dead, skeleton).
summon(summon_demon, imp).
summon(summon_elemental, elemental).
