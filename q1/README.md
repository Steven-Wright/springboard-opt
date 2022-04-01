# Q1

## Resources
### Pre-Optimization
#### Plan
```
EXPLAIN: -> Filter: (Student.id = <cache>((@v1)))  (cost=41.00 rows=40) (actual time=0.576..2.789 rows=1 loops=1)
    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.095..2.491 rows=400 loops=1)
```
#### Profile
```
+----------+------------+-----------------------------------------+
| Query_ID | Duration   | Query                                   |
+----------+------------+-----------------------------------------+
|        1 | 0.00150650 | SELECT name FROM Student WHERE id = @v1 |
+----------+------------+-----------------------------------------+
```
### Post-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Rows fetched before execution  (cost=0.00..0.00 rows=1) (actual time=0.000..0.001 rows=1 loops=1)
```
#### Profile
```
+----------+------------+-----------------------------------------+
| Query_ID | Duration   | Query                                   |
+----------+------------+-----------------------------------------+
|        1 | 0.00141125 | SELECT name FROM Student WHERE id = @v1 |
+----------+------------+-----------------------------------------+
```
## What was the bottleneck?
The database had to scan the Student table to find a row where id matched the value of v1.

## How did you identify it?
I identified it by running `EXPLAIN ANALYZE` on the query.

## What method(s) did you use to resolve the bottleneck?
I added a primary key to the Student table
```
ALTER TABLE Student ADD CONSTRAINT PRIMARY KEY (id);
```
