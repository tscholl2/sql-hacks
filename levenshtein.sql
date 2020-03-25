/*
 * Computes Levenshtein distance:
 * Restrictions: the words must have length < 1000.
 */
WITH RECURSIVE
    input(w1,w2) AS (VALUES(lower("zxy"),lower("abcdefghij"))),
    lengths(l1,l2) AS (SELECT length(w1)+1,length(w2)+1 FROM input),
    levenshtein(idx,A) AS (
        VALUES(0,'')
        UNION ALL
        SELECT
            idx+1,
            /*
            Set up a table A with A[0,*] = A[*,0] = 0.
            Let a,b be input strings with characters 1-indexed.
            d_{i,j} = {
                max(i,j) if min(i,j) = 0
                min(
                    d_{i-1,j} + 1,
                    d_{i,j-1} + 1,
                    d_{i-1,j-1} + (a[i] == b[j] ? 0 : 1)
                ) otherwise
            }
            The result is d_{len(a),len(b)}.
            In our setup, A is represented as a string of concatenated ints.
            i,j are computed from a single index variable:
                idx = i*len(b) + j
                i = idx / len(b)
                j = idx % len(b)
            So
                d_{i,j} = A[idx]
                d_{i-1,j} = A[idx-len(b)]
                d_{i,j-1} = A[idx - 1]
            To allow strings of length >= 10, we include leading 0s so all
            ints are 3-wide. This allowed strings of length < 1000.
            This is too slow to run for anything > 500.
            */
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