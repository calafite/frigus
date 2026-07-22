:- module(cfg_deity, [
    deity/2,
    altar/2,
    sac_val/2,
    blessing/3
]).

deity(sol, light).
deity(nox, dark).
deity(valkor, war).
deity(silva, nature).
deity(aether, magic).

altar(altar_of_sol, sol).
altar(altar_of_nox, nox).
altar(altar_of_valkor, valkor).
altar(altar_of_silva, silva).
altar(altar_of_aether, aether).

sac_val(gold, 1).
sac_val(raw_meat, 2).
sac_val(blue_lotus, 5).
sac_val(iron_ingot, 10).
sac_val(silver_ingot, 25).
sac_val(gold_ingot, 50).
sac_val(sunstone, 100).
sac_val(shadow_essence, 100).
sac_val(excalibur, 500).
sac_val(gungnir, 500).

blessing(sol, 100, buff(max_hp, 50, 9999)).
blessing(sol, 250, buff(hp_regen, 10, 9999)).
blessing(nox, 100, buff(dex, 10, 9999)).
blessing(nox, 250, buff(lifesteal, 5, 9999)).
blessing(valkor, 100, buff(str, 10, 9999)).
blessing(valkor, 250, buff(crit_chance, 15, 9999)).
blessing(silva, 100, buff(body, 20, 9999)).
blessing(silva, 250, buff(poison_resist, 50, 9999)).
blessing(aether, 100, buff(int, 10, 9999)).
blessing(aether, 250, buff(max_mp, 50, 9999)).
