-- link Teaching and Transcript sensibly

CREATE TEMPORARY TABLE IF NOT EXISTS table2 AS (
WITH fix_teach AS (
    SELECT ROW_NUMBER() OVER(PARTITION BY crsCode) AS m,
           crsCode,
           semester
    FROM Teaching
),
fix_trans AS (
    SELECT DENSE_RANK() OVER(PARTITION BY crsCode ORDER BY RAND()) AS m,
           crsCode,
           semester
    FROM Transcript
)

SELECT
    fix_teach.crsCode AS teach_crsCode,
    fix_teach.semester AS teach_semester,
    fix_trans.semester AS new_semester
FROM fix_teach
JOIN fix_trans USING (crsCode, m));

UPDATE Teaching JOIN table2 ON teach_crsCode = Teaching.crsCode AND teach_semester = Teaching.semester
SET Teaching.semester = new_semester;

DROP TABLE table2;


-- drop duplicate course entries
DELETE FROM Course WHERE crsCode = 'MGT157' AND crsName LIKE 'Human Robot%';
DELETE FROM Course WHERE crsCode = 'MGT382' AND crsName LIKE 'Introduction%';
DELETE FROM Course WHERE crsCode = 'EE820' AND crsName LIKE 'System Security%';
