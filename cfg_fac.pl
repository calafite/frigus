:- module(cfg_fac, [enemy/2, ally/2]).

enemy(criminal, guard).
enemy(criminal, citizen).
enemy(criminal, paladin).
enemy(criminal, merchant).
enemy(criminal, noble).

enemy(monster, guard).
enemy(monster, citizen).
enemy(monster, paladin).
enemy(monster, peasant).
enemy(monster, merchant).

enemy(undead, paladin).
enemy(undead, cleric).
enemy(undead, citizen).
enemy(undead, guard).

enemy(demon, angel).
enemy(demon, paladin).
enemy(demon, cleric).
enemy(demon, citizen).
enemy(demon, guard).

enemy(angel, demon).
enemy(angel, undead).
enemy(angel, cultist).

enemy(cultist, paladin).
enemy(cultist, guard).
enemy(cultist, citizen).

enemy(bandit, guard).
enemy(bandit, merchant).
enemy(bandit, noble).

ally(guard, citizen).
ally(guard, paladin).
ally(guard, merchant).
ally(guard, peasant).

ally(paladin, cleric).
ally(paladin, citizen).
ally(paladin, guard).
ally(paladin, angel).

ally(cleric, citizen).
ally(cleric, guard).

ally(demon, cultist).
ally(undead, necromancer).

ally(bandit, criminal).
ally(thief, criminal).
