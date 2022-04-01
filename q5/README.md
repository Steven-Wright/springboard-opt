# Q5
## Resources
### Pre-Optimization
#### Plan
```
EXPLAIN: -> Filter: <in_optimizer>(Transcript.studId,<exists>(select #3) is false)  (cost=3989.36 rows=3880) (actual time=3.840..47.059 rows=26 loops=1)
    -> Inner hash join (Student.id = Transcript.studId)  (cost=3989.36 rows=3880) (actual time=1.925..4.703 rows=26 loops=1)
        -> Table scan on Student  (cost=0.06 rows=400) (actual time=0.037..2.404 rows=400 loops=1)
        -> Hash
            -> Filter: (Transcript.crsCode = Course.crsCode)  (cost=107.22 rows=97) (actual time=0.967..1.790 rows=26 loops=1)
                -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=107.22 rows=97) (actual time=0.963..1.747 rows=26 loops=1)
                    -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.029..0.629 rows=100 loops=1)
                    -> Hash
                        -> Filter: (Course.deptId = <cache>((@v6)))  (cost=9.95 rows=10) (actual time=0.114..0.807 rows=24 loops=1)
                            -> Table scan on Course  (cost=9.95 rows=97) (actual time=0.090..0.652 rows=97 loops=1)
    -> Select #3 (subquery in condition; dependent)
        -> Limit: 1 row(s)  (cost=107.22 rows=1) (actual time=1.614..1.614 rows=0 loops=26)
            -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(Transcript.studId), true)  (cost=107.22 rows=97) (actual time=1.613..1.613 rows=0 loops=26)
                -> Filter: (<if>(outer_field_is_not_null, ((<cache>(Transcript.studId) = Transcript.studId) or (Transcript.studId is null)), true) and (Transcript.crsCode = Course.crsCode))  (cost=107.22 rows=97) (actual time=1.612..1.612 rows=0 loops=26)
                    -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=107.22 rows=97) (actual time=0.822..1.570 rows=32 loops=26)
                        -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.015..0.612 rows=100 loops=26)
                        -> Hash
                            -> Filter: (Course.deptId = <cache>((@v7)))  (cost=9.95 rows=10) (actual time=0.048..0.686 rows=31 loops=26)
                                -> Table scan on Course  (cost=9.95 rows=97) (actual time=0.017..0.561 rows=97 loops=26)
```
#### Profile
```
+----------+------------+-------------------------------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                                             |
+----------+------------+-------------------------------------------------------------------------------------------------------------------+
|        1 | 0.00393975 | SELECT * FROM Student,                                                                                            |
|          |            |     (SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode             |
|          |            |     AND studId NOT IN                                                                                             |
|          |            |     (SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias  |
|          |            | WHERE Student.id = alias.studId;                                                                                  |
+----------+------------+-------------------------------------------------------------------------------------------------------------------+
```
### Post-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Nested loop inner join  (cost=154.71 rows=619) (actual time=1.704..3.081 rows=26 loops=1)
    -> Nested loop antijoin  (cost=77.39 rows=619) (actual time=1.655..2.529 rows=26 loops=1)
        -> Nested loop inner join  (cost=13.06 rows=25) (actual time=0.464..1.207 rows=26 loops=1)
            -> Covering index lookup on Course using q5_index_2 (deptId=(@v6))  (cost=4.57 rows=24) (actual time=0.403..0.450 rows=24 loops=1)
            -> Covering index lookup on Transcript using q5_index (crsCode=Course.crsCode)  (cost=0.26 rows=1) (actual time=0.021..0.030 rows=1 loops=24)
        -> Single-row index lookup on <subquery3> using <auto_distinct_key> (studId=Transcript.studId)  (actual time=0.003..0.003 rows=0 loops=26)
            -> Materialize with deduplication  (cost=15.70..15.70 rows=25) (actual time=1.286..1.286 rows=32 loops=1)
                -> Filter: (Transcript.studId is not null)  (cost=13.20 rows=25) (actual time=0.105..1.061 rows=32 loops=1)
                    -> Nested loop inner join  (cost=13.20 rows=25) (actual time=0.102..1.041 rows=32 loops=1)
                        -> Covering index lookup on Course using q5_index_2 (deptId=(@v7))  (cost=4.61 rows=24) (actual time=0.068..0.142 rows=31 loops=1)
                        -> Covering index lookup on Transcript using q5_index (crsCode=Course.crsCode)  (cost=0.26 rows=1) (actual time=0.020..0.028 rows=1 loops=31)
    -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.63 rows=1) (actual time=0.020..0.020 rows=1 loops=26)
```
#### Profile
```
+----------+------------+-------------------------------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                                             |
+----------+------------+-------------------------------------------------------------------------------------------------------------------+
|        1 | 0.00578025 | SELECT * FROM Student,                                                                                            |
|          |            |     (SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode             |
|          |            |     AND studId NOT IN                                                                                             |
|          |            |     (SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias  |
|          |            | WHERE Student.id = alias.studId;                                                                                  |
+----------+------------+-------------------------------------------------------------------------------------------------------------------+

```
## What was the bottleneck?
- 2x Table scan on Course to find crsCode from deptId
- 2x Table scan on Transcript to find studId from crsCode
- Table scan on Student
## How did you identify it?
I identified it by running `EXPLAIN ANALYZE` on the query.
## What method(s) did you use to resolve the bottleneck?
I added an index on Course on (deptId, crsCode), an index on Transcript on (crsCode, studId), and a primary key on Student (id).

```
ALTER TABLE Course ADD INDEX q5_index_2 (deptId, crsCode);
ALTER TABLE Transcript ADD INDEX q5_index_2 (crsCode, studId);
ALTER TABLE Student ADD CONSTRAINT PRIMARY KEY (id);
```
