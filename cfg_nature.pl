:- module(cfg_nature, [
    crop_data/3,
    tamable/2,
    pet_food/2
]).

crop_data(wheat_seed, wheat, 5).
crop_data(carrot_seed, carrot, 3).
crop_data(potato_seed, potato, 4).
crop_data(herb_seed, blue_lotus, 6).
crop_data(fire_seed, fire_lily, 7).
crop_data(cotton_seed, cotton, 5).
crop_data(grape_seed, grapes, 4).

tamable(wolf, 12).
tamable(bear, 16).
tamable(giant_spider, 18).
tamable(shadow_panther, 20).
tamable(griffin, 25).
tamable(horse, 10).
tamable(fox, 8).
tamable(boar, 14).
tamable(basilisk, 22).

pet_food(wolf, raw_meat).
pet_food(bear, raw_fish).
pet_food(shadow_panther, raw_meat).
pet_food(giant_spider, raw_meat).
pet_food(griffin, raw_meat).
pet_food(horse, apple).
pet_food(fox, raw_meat).
pet_food(boar, apple).
pet_food(basilisk, raw_meat).
