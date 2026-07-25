:- module(quest_config, [quest_data/6]).

% quest_data(Id, Name, Desc, RecLvl, Objectives, Rewards)
% Objectives Format: [kill(Tag, Count), collect(Tag, Count)]
% Rewards Format: [xp(Amt), item(Tag, Qty)]

% --- Shire Quests ---
quest_data(rat_problem, "Rat Exterminator", "The local tavern cellar is being overrun by rats. The barkeep wants them cleared out.", 1,
           [kill(rat, 5)], [xp(50), item(gold, 20)]).

quest_data(gather_apples, "Apple Harvest", "The townsfolk need fresh apples from the local orchard to prepare for the upcoming festival.", 1,
           [collect(apple, 5)], [xp(30), item(gold, 15)]).

quest_data(bandit_bounty, "Bandit Threat", "Bandits have been ambushing travelers on the roads. Take out a few of them and report back.", 5,
           [kill(bandit, 3)], [xp(250), item(gold, 150), item(chainmail, 1)]).

quest_data(skeleton_cleanup, "Restless Dead", "The crypt beneath the temple is stirring with the undead. We must ensure they do not escape.", 4,
           [kill(skeleton, 5)], [xp(200), item(gold, 100)]).

quest_data(dragon_slayer, "The Elder Wyrm", "An ancient Elder Dragon slumbers in the volcano. It is a suicide mission, but if you succeed, you will be a legend.", 15,
           [kill(elder_dragon, 1)], [xp(5000), item(gold, 1500), item(diviners_orb, 1)]).

% --- Expansion Quests ---
quest_data(clearing_the_cove, "Clear the Sunken Cove", "The local Porthaven guard is overwhelmed. Pirates and giant crabs have infested the cove beneath the docks.", 10,
           [kill(pirate, 5), kill(crab, 5)], [xp(800), item(gold, 300), item(pirate_cutlass, 1)]).

quest_data(forge_materials, "Scrap for the Forge", "Brokk the Forgemaster in Highforge needs scrap metal salvaged from the iron golems in the ruined keep.", 12,
           [collect(scrap_metal, 5)], [xp(1000), item(gold, 400), item(dwarven_hammer, 1)]).

quest_data(ancient_relics, "Relics of the Past", "Scholars from Sylvandell are looking for ancient relics buried deep within the southern ruins.", 15,
           [collect(ancient_relic, 3)], [xp(1500), item(gold, 500)]).

quest_data(cultist_purge, "Purge the Cultists", "Dark cultists are performing unspeakable rituals in the ancient ruins at the Crossroads. Stop them.", 15,
           [kill(cultist, 6)], [xp(2000), item(gold, 600), item(mana_potion, 3)]).

quest_data(deep_threat, "Threat from the Deep", "The deep caverns beneath Highforge echo with the roars of gargoyles and rock worms. Thin their numbers.", 20,
           [kill(gargoyle, 4), kill(rock_worm, 4)], [xp(3000), item(gold, 800)]).
