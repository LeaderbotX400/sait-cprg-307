-- Clue 1: Find the animal with the most flowers in a single bed
SELECT fa.animal_name
FROM farm_animals fa
JOIN flower_beds fb ON fa.animal_id = fb.animal_id
WHERE fb.num_flowers = (SELECT MAX(num_flowers) FROM flower_beds);
