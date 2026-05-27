-- Clue 2: Transfer Marigold (Horse)'s lavender bed to Thistle
UPDATE flower_beds
SET animal_id = (SELECT animal_id FROM farm_animals WHERE animal_name = 'Thistle')
WHERE flower_type = 'Lavender'
  AND animal_id = (SELECT animal_id FROM farm_animals WHERE animal_name = 'Marigold' AND animal_type = 'Horse');
