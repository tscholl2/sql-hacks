/*
 * Computes Levenshtein distance:
 * Restrictions: the words must have length < 1000.
 */
WITH RECURSIVE
    input(w1,w2) AS (VALUES(lower("z"),lower("abcdefghij"))),
    lengths(l1,l2) AS (SELECT length(w1)+1,length(w2)+1 FROM input),
    levenshtein(idx,A) AS (
        VALUES(0,'')
        UNION ALL
        SELECT
            idx+1,
            A||printf("%03d",(CASE WHEN min(idx/l2,idx%l2)=0 THEN max(idx/l2,idx%l2) ELSE
            min(
                substr(A,1+3*(idx-l2),3)+1,
                substr(A,1+3*(idx-1),3)+1,
                substr(A,1+3*(idx-l2-1),3)+(substr(w1,(idx/l2),1)!=substr(w2,(idx%l2),1))
            )END))
        FROM levenshtein JOIN input JOIN lengths WHERE idx<l1*l2 ORDER BY 1 ASC
    )
SELECT CAST (substr(A,-3,3) AS INTEGER) from levenshtein ORDER BY idx DESC LIMIT 1
;