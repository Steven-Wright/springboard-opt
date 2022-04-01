# Q3
## Resources
### Pre-Optimization
#### Plan
```
EXPLAIN: -> Inner hash join (Student.id = `<subquery2>`.studId)  (cost=414.91 rows=400) (actual time=1.404..3.800 rows=2 loops=1)
    -> Table scan on Student  (cost=5.04 rows=400) (actual time=0.080..2.279 rows=400 loops=1)
    -> Hash
        -> Table scan on <subquery2>  (cost=0.26..2.62 rows=10) (actual time=0.005..0.006 rows=2 loops=1)
            -> Materialize with deduplication  (cost=11.51..13.88 rows=10) (actual time=1.053..1.054 rows=2 loops=1)
                -> Filter: (Transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.330..1.000 rows=2 loops=1)
                    -> Filter: (Transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.326..0.995 rows=2 loops=1)
                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.105..0.765 rows=100 loops=1)
```
#### Profile
```
+----------+------------+------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                    |
+----------+------------+------------------------------------------------------------------------------------------+
|        1 | 0.00604325 | SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4) |
+----------+------------+------------------------------------------------------------------------------------------+
```
### Post-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Nested loop inner join  (cost=1.93 rows=2) (actual time=0.154..0.214 rows=2 loops=1)
    -> Remove duplicates from input sorted on q3_index  (cost=0.48 rows=2) (actual time=0.093..0.128 rows=2 loops=1)
        -> Covering index lookup on Transcript using q3_index (crsCode=(@v4))  (cost=0.48 rows=2) (actual time=0.087..0.117 rows=2 loops=1)
    -> Single-row index lookup on Student using PRIMARY (id=Transcript.studId)  (cost=1.35 rows=1) (actual time=0.039..0.039 rows=1 loops=2)
```
#### Profile
```
+----------+------------+------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                    |
+----------+------------+------------------------------------------------------------------------------------------+
|        1 | 0.00211200 | SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4) |
+----------+------------+------------------------------------------------------------------------------------------+
```
## What was the bottleneck?
The database had to perform table scans on Student and Transcript, as well filtering non-null values from Transcript.studId.

## How did you identify it?
I identified it by running `EXPLAIN ANALYZE` on the query.

## What method(s) did you use to resolve the bottleneck?
I added a primary key to the Student table, an index (crsCode, studId) on Transcript, and a non-null constraint on Transcript studId.

```
ALTER TABLE Student ADD CONSTRAINT PRIMARY KEY (id);
ALTER TABLE Transcript ADD INDEX q3_index (crsCode, studId);
ALTER TABLE Transcript MODIFY studId INT NOT NULL;
```
