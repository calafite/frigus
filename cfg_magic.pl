:- module(cfg_magic, [
    cost/2,
    cooldown/2,
    spell_nature/2,
    req_race/2
]).

cost(fireball, 5).
cost(iceblast, 6).
cost(bash, 3).
cost(mend, 4).
cost(rejuvenate, 8).
cost(raise_dead, 10).
cost(haste, 5).
cost(stoneskin, 6).
cost(meteor_storm, 25).
cost(judgment, 20).
cost(fireblast, 10).
cost(holy_light, 6).
cost(earthquake, 18).
cost(chain_lightning, 8).

cooldown(fireball, 3).
cooldown(iceblast, 4).
cooldown(bash, 2).
cooldown(mend, 2).
cooldown(rejuvenate, 4).
cooldown(raise_dead, 8).
cooldown(haste, 6).
cooldown(stoneskin, 6).
cooldown(meteor_storm, 10).
cooldown(judgment, 8).
cooldown(fireblast, 5).
cooldown(holy_light, 4).
cooldown(earthquake, 8).
cooldown(chain_lightning, 4).

spell_nature(fireball, damage).
spell_nature(iceblast, damage).
spell_nature(mend, healing).
spell_nature(rejuvenate, healing).
spell_nature(raise_dead, necromancy).
spell_nature(haste, buff).
spell_nature(stoneskin, buff).
spell_nature(meteor_storm, cataclysm).
spell_nature(judgment, cataclysm).
spell_nature(fireblast, damage).
spell_nature(holy_light, healing).
spell_nature(earthquake, cataclysm).
spell_nature(chain_lightning, damage).

req_race(meteor_storm, demigod).
req_race(earthquake, demigod).
req_race(judgment, angel).
