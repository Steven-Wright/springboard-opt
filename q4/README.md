# Q4
## Resources
### Pre-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Inner hash join (Student.id = Transcript.studId)  (cost=1313.72 rows=160) (actual time=6.550..8.998 rows=1 loops=1)
    -> Table scan on Student  (cost=0.03 rows=400) (actual time=0.033..2.275 rows=400 loops=1)
    -> Hash
        -> Inner hash join (Professor.id = Teaching.profId)  (cost=1144.90 rows=4) (actual time=3.729..6.279 rows=1 loops=1)
            -> Filter: (Professor.`name` = <cache>((@v5)))  (cost=0.95 rows=4) (actual time=0.245..2.792 rows=1 loops=1)
                -> Table scan on Professor  (cost=0.95 rows=400) (actual time=0.053..2.234 rows=400 loops=1)
            -> Hash
                -> Filter: ((Teaching.semester = Transcript.semester) and (Teaching.crsCode = Transcript.crsCode))  (cost=1010.70 rows=100) (actual time=1.893..3.190 rows=100 loops=1)
                    -> Inner hash join (<hash>(Teaching.semester)=<hash>(Transcript.semester)), (<hash>(Teaching.crsCode)=<hash>(Transcript.crsCode))  (cost=1010.70 rows=100) (actual time=1.880..2.921 rows=100 loops=1)
                        -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.720..1.436 rows=100 loops=1)
                        -> Hash
                            -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.103..0.767 rows=100 loops=1)
```
#### Profile
```
+----------+------------+--------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                      |
+----------+------------+--------------------------------------------------------------------------------------------+
|        1 | 0.00989650 | SELECT name FROM Student,                                                                  |
|          |            |     (SELECT studId FROM Transcript,                                                        |
|          |            |           (SELECT crsCode, semester FROM Professor                                         |
|          |            |	          JOIN Teaching                                                              |
|          |            |                 WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1   |
|          |		|     WHERE Transcript.crsCode = alias1.                                                     |
+----------+------------+--------------------------------------------------------------------------------------------+
```
### Post-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Nested loop inner join  (cost=1.78 rows=1) (actual time=0.202..0.239 rows=1 loops=1)
    -> Nested loop inner join  (cost=1.05 rows=1) (actual time=0.160..0.195 rows=1 loops=1)
        -> Nested loop inner join  (cost=0.70 rows=1) (actual time=0.119..0.134 rows=1 loops=1)
            -> Covering index lookup on Professor using q4_index_1 (name=(@v5))  (cost=0.35 rows=1) (actual time=0.082..0.090 rows=1 loops=1)
            -> Covering index lookup on Teaching using q4_index_2 (profId=Professor.id)  (cost=0.35 rows=1) (actual time=0.034..0.041 rows=1 loops=1)
        -> Covering index lookup on Transcript using q4_index_3 (crsCode=Teaching.crsCode, semester=Teaching.semester)  (cost=0.35 rows=1) (actual time=0.039..0.059 rows=1 loops=1)
    -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=0.72 rows=1) (actual time=0.040..0.040 rows=1 loops=1)
```
#### Profile
```
+----------+------------+--------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                      |
+----------+------------+--------------------------------------------------------------------------------------------+
|        1 | 0.00214000 | SELECT name FROM Student,                                                                  |
|          |            |     (SELECT studId FROM Transcript,                                                        |
|	   |	        |           (SELECT crsCode, semester FROM Professor                                         |
|          |            |                 JOIN Teaching                                                              |
|	   |	        |                 WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1   |
|	   |		|     WHERE Transcript.crsCode = alias1.                                                     |
+----------+------------+--------------------------------------------------------------------------------------------+

```
## What was the bottleneck?
- Table scan on Professor to find id from name
- Table scan on Teaching to find crsCode, semester from profId
- Table scan on Transcript to find studId from crsCode, semester
- Table scan on Student to find studId

## How did you identify it?
I identified it by running `EXPLAIN ANALYZE` on the query.

## What method(s) did you use to resolve the bottleneck?
I added an index on Professor on (name, id), an index on Teaching on (profId, crsCode, semester), an index on Transcript on (crsCode, semester, studId) and a primary key on Student (id).

```
ALTER TABLE Student ADD CONSTRAINT PRIMARY KEY (id);
ALTER TABLE Professor ADD INDEX q4_index_1 (name, id);
ALTER TABLE Teaching ADD INDEX q4_index_2 (profId, crsCode, semester);
ALTER TABLE Transcript ADD INDEX q4_index_3 (crsCode, semester, studId);
```
