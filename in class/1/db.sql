-- Drop tables 
DROP TABLE escape_steps;
DROP TABLE clues;
DROP TABLE flower_beds;
DROP TABLE farm_animals;

-- Create FARM_ANIMALS table
CREATE TABLE FARM_ANIMALS (
  animal_id NUMBER PRIMARY KEY,
  animal_name VARCHAR2(50) NOT NULL,
  animal_type VARCHAR2(50) NOT NULL,
  is_distressed CHAR(1) DEFAULT 'Y' CHECK (is_distressed IN ('Y', 'N'))
);

-- Create FLOWER_BEDS table  
CREATE TABLE FLOWER_BEDS (
  bed_id NUMBER PRIMARY KEY,
  flower_type VARCHAR2(50) NOT NULL,
  num_flowers NUMBER NOT NULL,
  color VARCHAR2(50) NOT NULL,
  animal_id  NUMBER REFERENCES farm_animals(animal_id)
);

-- Create CLUES table
CREATE TABLE CLUES (
  clue_id NUMBER PRIMARY KEY,
  clue_description VARCHAR2(200) NOT NULL,
  is_hidden CHAR(1) DEFAULT 'Y' CHECK (is_hidden IN ('Y', 'N')),
  bed_id NUMBER NOT NULL,
  CONSTRAINT fk_clues_flower_beds FOREIGN KEY (bed_id)
    REFERENCES FLOWER_BEDS(bed_id)
);

-- Create ESCAPE_STEPS table
CREATE TABLE ESCAPE_STEPS (
  step_id NUMBER PRIMARY KEY,
  step_description VARCHAR2(200) NOT NULL,
  required_clue_id NUMBER NOT NULL,
  CONSTRAINT fk_escape_steps_clues FOREIGN KEY (required_clue_id)
    REFERENCES CLUES(clue_id)
);



-- Populate FARM_ANIMALS table
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (1, 'Clover', 'Donkey', 'Y');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (2, 'Daisy', 'Sheep', 'N');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (3, 'Buttercup', 'Cow', 'Y');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (4, 'Wilbur', 'Pig', 'N');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (5, 'Blossom', 'Chicken', 'Y');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (6, 'Dandelion', 'Goat', 'N');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (7, 'Marigold', 'Horse', 'Y');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (8, 'Clementine', 'Duck', 'N');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (9, 'Sunflower', 'Chicken', 'Y');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (10, 'Thistle', 'Sheep', 'N');
INSERT INTO FARM_ANIMALS (animal_id, animal_name, animal_type, is_distressed)
VALUES (11, 'Marigold', 'Duck', 'N');

-- Populate FLOWER_BEDS table
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (1, 'Daisy', 25, 'White', 1);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (2, 'Tulip', 15, 'Red', 10);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (3, 'Sunflower', 20, 'Yellow', 3);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (4, 'Lavender', 30, 'Purple', 7);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (5, 'Rose', 10, 'Green', 8);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (6, 'Bluebell', 18, 'Blue', 2);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (7, 'Marigold', 22, 'Orange', 9);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (8, 'Poppy', 12, 'Red', 4);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (9, 'Dandelion', 35, 'Yellow', 6);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (10, 'Iris', 16, 'Purple', 7);
INSERT INTO FLOWER_BEDS (bed_id, flower_type, num_flowers, color, animal_id)
VALUES (11, 'Lavender', 3, 'Purple', 11);

-- Populate CLUES table
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (1, 'The distressed donkey has a message for you.', 'Y', 1);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (2, 'The sheep with the most flowers is hiding something.', 'Y', 2);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (3, 'The sunflowers hold the key to unlocking the first step.', 'Y', 3);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (4, 'The lavender bed conceals a vital piece of information.', 'Y', 4);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (5, 'The roses hold a secret that will lead you to the next clue.', 'Y', 5);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (6, 'The bluebell bed contains a crucial SQL statement.', 'Y', 6);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (7, 'The marigolds reveal the next step in the escape plan.', 'Y', 7);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (8, 'The poppies hold the answer to a pressing question.', 'Y', 8);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (9, 'The dandelions contain a vital SQL query.', 'Y', 9);
INSERT INTO CLUES (clue_id, clue_description, is_hidden, bed_id)
VALUES (10, 'The irises hold the final piece of the puzzle.', 'Y', 10);

-- Populate ESCAPE_STEPS table
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (1, 'Calm the distressed donkey and learn the first clue.', 1);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (2, 'Identify the sheep with the most flowers and extract the hidden information.', 2);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (3, 'Use the sunflower clue to perform a crucial SQL query.', 3);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (4, 'Analyze the lavender bed clue to uncover the next step.', 4);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (20, 'The roses whisper:  6E65656420612074656E74 in base of 16.  Change this to text and the last word is your final clue.', 5);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (6, 'Employ the SQL statement from the bluebell bed to progress.', 6);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (7, 'Use the marigold clue to determine the next action.', 7);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (8, 'Solve the puzzle hidden in the poppy bed to unlock the next step.', 8);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (9, 'Execute the SQL query from the dandelion bed to uncover a crucial piece of information.', 9);
INSERT INTO ESCAPE_STEPS (step_id, step_description, required_clue_id)
VALUES (10, 'Combine all the clues to find the final solution and escape the pasture.', 10);



COMMIT;