-- Clue 3: Retrieve the 5th hidden clue along with its escape step and step id
SELECT es.step_id, c.clue_description, es.step_description
FROM clues c
JOIN escape_steps es ON c.clue_id = es.required_clue_id
WHERE c.is_hidden = 'Y'
  AND c.clue_id = (
    SELECT clue_id
    FROM (
      SELECT clue_id, ROW_NUMBER() OVER (ORDER BY clue_id) AS rn
      FROM clues
      WHERE is_hidden = 'Y'
    )
    WHERE rn = 5
  );
