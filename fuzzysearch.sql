.parameter set $needle 'Lorm ipsum dolor'
.parameter set $haystack 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
--.header on
--.mode columns
WITH RECURSIVE
    raw_input(val,arg) AS (
        VALUES($needle,'needle')
        UNION VALUES($haystack,'haystack')
    ),
    input(val,arg) AS (
        SELECT
            -- 0a=\n, 0d=\r, 09=\t
            replace(replace(replace(lower(val),x'0a',' '),x'0d',' '),x'09',' '),
            arg
        FROM raw_input
    ),
    split_words(idx,word,arg) AS (
        WITH RECURSIVE
            split(idx,word,prev,rest,arg) AS (
                SELECT 0,'','',val,arg FROM input
                UNION ALL
                SELECT
                    idx+1,
                    CASE WHEN instr(' ',prev) THEN '' ELSE word||prev END,
                    substr(rest,0,2),
                    substr(rest,2),
                    arg
                FROM split WHERE prev != '' OR rest != ''
            )
        SELECT idx-length(word),word,arg FROM split
        WHERE word!='' AND (instr(' ',prev) OR prev='')
    ),
    hay_words(i,idx,word) AS (
        SELECT row_number() OVER (ORDER BY idx),idx,word FROM split_words WHERE arg='haystack'
    ),
    needle_words(i,idx,word) AS (
        SELECT row_number() OVER (ORDER BY idx),idx,word FROM split_words WHERE arg='needle'
    ),
    distances(i,j,d) AS (
        SELECT needle_words.i,hay_words.i,(
            WITH RECURSIVE
                input(w1,w2) AS (VALUES(needle_words.word,hay_words.word)),
                lengths(l1,l2) AS (SELECT length(w1)+1,length(w2)+1 FROM input),
                levenshtein(idx,A) AS (
                    VALUES(0,'')
                    UNION ALL
                    SELECT
                        idx+1,
                        A||printf('%03d',(CASE WHEN min(idx/l2,idx%l2)=0 THEN max(idx/l2,idx%l2) ELSE
                        min(
                            substr(A,1+3*(idx-l2),3)+1,
                            substr(A,1+3*(idx-1),3)+1,
                            substr(A,1+3*(idx-l2-1),3)+(substr(w1,(idx/l2),1)!=substr(w2,(idx%l2),1))
                        )END))
                    FROM levenshtein JOIN input JOIN lengths WHERE idx<=l1*l2
                )
            SELECT CAST (substr(A,-3,3) AS INTEGER) from levenshtein JOIN lengths WHERE idx=l1*l2
        ) FROM hay_words CROSS JOIN needle_words WHERE hay_words.i>=needle_words.i
    ),
    needle_count(n) AS (SELECT count(*) FROM needle_words),
    hay_count(m) AS (SELECT count(*) FROM hay_words),
    phrase_distances(j,t) AS (
        SELECT
            j,
            (SELECT sum(d) FROM distances WHERE j-i=D.j-D.i)
        FROM distances AS D JOIN needle_count JOIN hay_count
        WHERE i=1 AND j<=m-n+1
    ),
    best_score(t) AS (SELECT min(t) FROM phrase_distances),
    top_matches(idx_start,idx_end) AS (
        SELECT
            idx,
            (SELECT idx+length(word)-1 FROM hay_words WHERE i=j+n-1)
        FROM phrase_distances JOIN needle_count JOIN best_score
        JOIN hay_words ON phrase_distances.j=hay_words.i
        WHERE phrase_distances.t=best_score.t
    ),
    result(score,highlighted) AS (
        WITH RECURSIVE
            helper(i,s) AS (
                VALUES(0,'')
                UNION ALL
                SELECT
                    i+1,
                    CASE WHEN 1 IN (SELECT i+1 BETWEEN idx_start AND idx_end FROM top_matches)
                        THEN s||'\\e[30;103m'||substr(val,i+1,1)||'\\e[0m'
                        ELSE s||substr(val,i+1,1)
                    END
                FROM helper JOIN raw_input WHERE arg='haystack' AND i<=length(val)
            )
        SELECT t,s FROM helper JOIN best_score ORDER BY i DESC LIMIT 1
    )
--SELECT * FROM top_matches
--SELECT * FROM distances ORDER BY j ASC,i DESC
SELECT * FROM result
;
