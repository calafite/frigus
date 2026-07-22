:- module(cfg_alchemy, [
    ingredient_aspect/2,
    potion_recipe/2
]).

ingredient_aspect(blue_lotus, mana).
ingredient_aspect(fire_lily, fire).
ingredient_aspect(berries, life).
ingredient_aspect(cave_mushroom, shadow).
ingredient_aspect(spider_venom, poison).
ingredient_aspect(snake_skin, poison).
ingredient_aspect(dragon_scale, fire).
ingredient_aspect(dragon_scale, armor).
ingredient_aspect(griffin_feather, air).
ingredient_aspect(shadow_essence, shadow).
ingredient_aspect(sunstone, light).
ingredient_aspect(basilisk_scale, stone).
ingredient_aspect(holy_water, light).

potion_recipe([life, life], health_potion).
potion_recipe([life, life, life], greater_health_potion).
potion_recipe([mana, mana], mana_potion).
potion_recipe([mana, mana, mana], greater_mana_potion).
potion_recipe([fire, mana], potion_of_firebreathing).
potion_recipe([air, shadow], potion_of_invisibility).
potion_recipe([armor, stone], potion_of_stoneskin).
potion_recipe([poison, poison], deadly_poison).
potion_recipe([life, light], elixir_of_life).
potion_recipe([poison, shadow], potion_of_blindness).
potion_recipe([air, life], potion_of_haste).
