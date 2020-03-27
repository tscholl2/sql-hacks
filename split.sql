/*
 * Splits a string on whitespace characters.
 */
WITH RECURSIVE
    split(idx,word,prev,rest) AS (
        VALUES(0,'','','hello world')
        UNION ALL
        SELECT
            idx+1,
            -- 20=space,0a=newline,0d=carriagereturn,09=tab
            CASE WHEN instr(x'200A0D09',prev)
                THEN ''
                ELSE word||prev
            END,
            substr(rest,0,2), -- last character seen
            substr(rest,2) -- skips one character
        FROM split WHERE prev != '' OR rest != ''
    ),
    words(w,idx) AS (
        SELECT word,idx-length(word) FROM split
        WHERE word!='' AND (instr(x'200A0D09',prev) OR prev='')
    )
SELECT * FROM words
;