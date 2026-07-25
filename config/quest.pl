:- module(quest_config, [quest_data/6]).

% quest_data(Id, Name, Desc, RecLvl, Objectives, Rewards)
% Objectives Format: [kill(Tag, Count), collect(Tag, Count)]
% Rewards Format: [xp(Amt), item(Tag, Qty)]

quest_data(rat_problem, "Rat Exterminator", "The local tavern cellar is being overrun by rats. The barkeep wants them cleared out.", 1,
           [kill(rat, 5)], [xp(50), item(gold, 20)]).

quest_data(spider_venom, "Arachnid Menace", "Giant spiders have been spotted in the caverns. Thin their numbers before they reach town.", 3,
           [kill(giant_spider, 4)], [xp(150), item(gold, 50), item(health_potion, 2)]).

quest_data(gather_apples, "Apple Harvest", "The townsfolk need fresh apples from the local orchard to prepare for the upcoming festival.", 1,
           [collect(apple, 5)], [xp(30), item(gold, 15)]).

quest_data(bandit_bounty, "Bandit Threat", "Bandits have been ambushing travelers on the roads. Take out a few of them and report back.", 5,
           [kill(bandit, 3)], [xp(250), item(gold, 150), item(chainmail, 1)]).

quest_data(skeleton_cleanup, "Restless Dead", "The crypt beneath the temple is stirring with the undead. We must ensure they do not escape.", 4,
           [kill(skeleton, 5)], [xp(200), item(gold, 100)]).

quest_data(dragon_slayer, "The Elder Wyrm", "An ancient Elder Dragon slumbers in the volcano. It is a suicide mission, but if you succeed, you will be a legend.", 15,
           [kill(elder_dragon, 1)], [xp(5000), item(gold, 1500), item(diviners_orb, 1)]).
