# Loops in BigQuery

## Using scripting in BigQuery to calculate Fibonacci


```sql
-- how many numbers do we want
DECLARE n int64;
-- this is where we collect our result
DECLARE f ARRAY<INT64> DEFAULT [0,1];
-- our counter (we already generated the 0th and 1st numbers)
DECLARE i INT64 DEFAULT 1;

-- change this to adjust the length of the sequence
SET n = 8;

-- we will do this until we have n numbers
WHILE i < n DO
  SET f = ARRAY_CONCAT(f, [ARRAY_REVERSE(f)[OFFSET(0)] + ARRAY_REVERSE(f)[OFFSET(1)]]);
  SET i = i + 1;
END WHILE;

-- flatten our array so that it looks like a regular table
SELECT
   (row_number() over (order by fibonacci)) - 1 as n
   ,fibonacci
FROM UNNEST(f) as fibonacci
ORDER BY fibonacci asc;
```

- how to declare variables
- how to start a while loop
- concat arrays
- no negative indexing so we have to reverse the array and find the 2 latest numbers

Let's say we're only interested in the nth number, but not the full sequence up to n.
Then we can do this without arrays:

```sql
DECLARE a INT64 DEFAULT 0;
DECLARE b INT64 DEFAULT 1;
DECLARE tmp INT64 DEFAULT 0;
DECLARE answer INT64 DEFAULT 0;
DECLARE n INT64;

SET n = 3;

WHILE n > 1 DO
    SET tmp = b;
    SET b = a + b;
    SET a = tmp;
    SET n = n - 1;
END WHILE;

IF n = 0 THEN
  SET answer = a;
ELSE
  SET answer = b;
END IF;

SELECT answer;
```

- runs faster as we don't need to create arrays at each step (I think)
- I prefer to do decrement n as we no longer need i this way
- we have to handle the special case of i = 0 when the answer is the 0th number (a) 