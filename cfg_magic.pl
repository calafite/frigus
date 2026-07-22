:- module(cfg_magic, [
    cost/2, cooldown/2, spell_nature/2, req_race/2,
    aoe/1, friendly_fire_enabled/1, summon/2
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

req_race(meteor_storm, demigod).
req_race(earthquake, demigod).
req_race(judgment, angel).
req_race(holy_light, angel).
req_race(bloodline_curse, demon).
req_race(summon_demon, demon).
req_race(_, none).

aoe(meteor_storm).
aoe(earthquake).
aoe(chain_lightning).

friendly_fire_enabled(meteor_storm).
friendly_fire_enabled(earthquake).

summon(raise_dead, skeleton).
summon(summon_demon, imp).
summon(summon_elemental, elemental).
