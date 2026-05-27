-- Clue 4: Extract hex from the 5th hidden clue's escape step and decode it
SELECT UTL_RAW.CAST_TO_VARCHAR2(
    HEXTORAW(
        REGEXP_SUBSTR(
            (SELECT es.step_description
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
               )),
            '[0-9A-Fa-f]{15,}'
        )
    )
) AS decoded_message
FROM DUAL;
