# Q6
## Resources
### Pre-Optimization
#### Plan
EXPLAIN: -> Nested loop inner join  (cost=1041.00 rows=0) (actual time=6.311..6.311 rows=0 loops=1)
    -> Filter: (Student.id is not null)  (cost=41.00 rows=400) (actual time=0.109..2.631 rows=400 loops=1)
        -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.105..2.428 rows=400 loops=1)
    -> Covering index lookup on alias using <auto_key0> (studId=Student.id)  (actual time=0.001..0.001 rows=0 loops=400)
        -> Materialize  (cost=0.00..0.00 rows=0) (actual time=3.044..3.044 rows=0 loops=1)
            -> Filter: (count(0) = (select #5))  (actual time=2.149..2.149 rows=0 loops=1)
                -> Table scan on <temporary>  (actual time=0.002..0.002 rows=0 loops=1)
                    -> Aggregate using temporary table  (actual time=2.147..2.147 rows=0 loops=1)
                        -> Nested loop inner join  (cost=1020.25 rows=10000) (actual time=2.117..2.117 rows=0 loops=1)
                            -> Filter: (Transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.037..0.842 rows=100 loops=1)
                                -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.035..0.786 rows=100 loops=1)
                            -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=Transcript.crsCode)  (actual time=0.004..0.004 rows=0 loops=100)
                                -> Materialize with deduplication  (cost=120.52..120.52 rows=100) (actual time=1.189..1.189 rows=0 loops=1)
                                    -> Filter: (Course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.676..0.676 rows=0 loops=1)
                                        -> Filter: (Teaching.crsCode = Course.crsCode)  (cost=110.52 rows=100) (actual time=0.675..0.675 rows=0 loops=1)
                                            -> Inner hash join (<hash>(Teaching.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.674..0.674 rows=0 loops=1)
                                                -> Table scan on Teaching  (cost=0.13 rows=100) (never executed)
                                                -> Hash
                                                    -> Filter: (Course.deptId = <cache>((@v8)))  (cost=10.25 rows=10) (actual time=0.640..0.640 rows=0 loops=1)
                                                        -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.030..0.528 rows=97 loops=1)
                -> Select #5 (subquery in condition; uncacheable)
                    -> Aggregate: count(0)  (cost=211.25 rows=1000)
                        -> Nested loop inner join  (cost=111.25 rows=1000)
                            -> Filter: ((Course.deptId = <cache>((@v8))) and (Course.crsCode is not null))  (cost=10.25 rows=10)
                                -> Table scan on Course  (cost=10.25 rows=100)
                            -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=Course.crsCode)
                                -> Materialize with deduplication  (cost=20.25..20.25 rows=100)
                                    -> Filter: (Teaching.crsCode is not null)  (cost=10.25 rows=100)
                                        -> Table scan on Teaching  (cost=10.25 rows=100)
            -> Select #5 (subquery in projection; uncacheable)
                -> Aggregate: count(0)  (cost=211.25 rows=1000)
                    -> Nested loop inner join  (cost=111.25 rows=1000)
                        -> Filter: ((Course.deptId = <cache>((@v8))) and (Course.crsCode is not null))  (cost=10.25 rows=10)
                            -> Table scan on Course  (cost=10.25 rows=100)
                        -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=Course.crsCode)
                            -> Materialize with deduplication  (cost=20.25..20.25 rows=100)
                                -> Filter: (Teaching.crsCode is not null)  (cost=10.25 rows=100)
                                    -> Table scan on Teaching  (cost=10.25 rows=100)
#### Profile
+----------+------------+------------------------------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                                            |
+----------+------------+------------------------------------------------------------------------------------------------------------------+
|        1 | 0.04423525 | SELECT name FROM Student,                                                                                        |
|          |            |   (SELECT studId                                                                                                 |
|          |            |    WHERE crsCode IN                                                                                              |
|          |            |       (SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))              |
|          |            |        GROUP BY studId                                                                                           |
|          |            |        HAVING COUNT(*) =                                                                                         |
|          |            |           (SELECT COUNT(*) FROM Course WHERE deptId = @ AND crsCode IN (SELECT crsCode FROM Teaching))) as alias |
|          |            | WHERE id = alias.studId                                                                                          |
+----------+------------+------------------------------------------------------------------------------------------------------------------+
### Post-Optimization
#### Plan
EXPLAIN: -> Nested loop inner join  (cost=21.50 rows=0) (actual time=2.014..2.014 rows=0 loops=1)
    -> Table scan on a  (cost=2.50..2.50 rows=0) (actual time=0.001..0.001 rows=0 loops=1)
        -> Materialize  (cost=2.50..2.50 rows=0) (actual time=2.012..2.012 rows=0 loops=1)
            -> Filter: (count = (select #5))  (actual time=1.980..1.980 rows=0 loops=1)
                -> Table scan on <temporary>  (actual time=0.001..0.006 rows=19 loops=1)
                    -> Aggregate using temporary table  (actual time=1.957..1.968 rows=19 loops=1)
                        -> Nested loop inner join  (cost=21.86 rows=20) (actual time=0.637..1.229 rows=19 loops=1)
                            -> Table scan on classes  (cost=0.14..2.74 rows=20) (actual time=0.006..0.018 rows=19 loops=1)
                                -> Materialize CTE classes if needed  (cost=12.48..15.07 rows=20) (actual time=0.597..0.616 rows=19 loops=1)
                                    -> Nested loop semijoin  (cost=10.38 rows=20) (actual time=0.136..0.520 rows=19 loops=1)
                                        -> Covering index lookup on Course using q6_index_1 (deptId=(@v8))  (cost=3.65 rows=19) (actual time=0.096..0.144 rows=19 loops=1)
                                        -> Covering index lookup on Teaching using q6_index_2 (crsCode=Course.crsCode)  (cost=0.26 rows=1) (actual time=0.019..0.019 rows=1 loops=19)
                            -> Covering index lookup on Transcript using q6_index_3 (crsCode=classes.crsCode)  (cost=0.26 rows=1) (actual time=0.022..0.030 rows=1 loops=19)
                -> Select #5 (subquery in condition; uncacheable)
                    -> Aggregate: count(0)  (cost=12.58..17.03 rows=20) (actual time=0.022..0.022 rows=1 loops=19)
                        -> Table scan on classes  (cost=0.14..2.74 rows=20) (actual time=0.002..0.007 rows=19 loops=19)
                            -> Materialize CTE classes if needed (query plan printed elsewhere)  (cost=12.48..15.07 rows=20) (never executed)
            -> Select #5 (subquery in projection; uncacheable)
                -> Aggregate: count(0)  (cost=12.58..17.03 rows=20) (actual time=0.022..0.022 rows=1 loops=19)
                    -> Table scan on classes  (cost=0.14..2.74 rows=20) (actual time=0.002..0.007 rows=19 loops=19)
                        -> Materialize CTE classes if needed (query plan printed elsewhere)  (cost=12.48..15.07 rows=20) (never executed)
    -> Single-row index lookup on Student using PRIMARY (id=a.studId)  (cost=1.01 rows=1) (never executed)
#### Profile
+----------+------------+------------------------------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                                            |
+----------+------------+------------------------------------------------------------------------------------------------------------------+
|        1 | 0.00586350 | WITH classes AS                                                                                                  |
|          |            | (                                                                                                                |
|          |            |     SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching)                  |
|          |            | )                                                                                                                |
|          |            | SELECT name                                                                                                      |
|          |            | FROM student                                                                                                     |
|          |            | JOIN (                                                                                                           |
|          |            |     SELECT studId, COUNT(*) as count                                                                             |
|          |            |     FROM Transcript                                                                                              |
|          |            |     JOIN classes USING (crsCode)                                                                                 |
|          |            |     GROUP BY studId                                                                                              |
|          |            |     HAVING count = (SELECT COUNT(*) FROM classes)) AS a                                                          |
|          |            | ON Student.id = a.studId                                                                                         |
+----------+------------+------------------------------------------------------------------------------------------------------------------+
## What was the bottleneck?
Table scans:
- 1 Student
- 1 Transcript
- 3 Teaching
- 3 Course

Duplicative effort to find all valid courses for department 8.

## How did you identify it?
I inspected the pre-optimization plan using EXPLAIN ANALYZE on the query.

## What method(s) did you use to resolve the bottleneck?
I rewrote the query to use a CTE for the crsCodes for courses with deptId = @v8 and crsCode in Teaching. I added a primary key to Student, a covering index on Course (deptId, crsCode), an index on Teaching (crsCode), and finally a covering index on Transcript (crsCode, studId).

ALTER TABLE Course ADD INDEX q6_index_1 (deptId, crsCode);
ALTER TABLE Teaching ADD INDEX q6_index_2 (crsCode);
ALTER TABLE Transcript ADD INDEX q6_index_3 (crsCode, studId);

With classes AS 
(
	SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching)
)
SELECT name 
FROM Student
JOIN (
    SELECT studId, COUNT(*) AS count 
    FROM Transcript 
    JOIN classes USING (crsCode) 
    GROUP BY studId 
    HAVING count = (SELECT COUNT(*) FROM classes)) AS a 
    ON Student.id = a.studId;


