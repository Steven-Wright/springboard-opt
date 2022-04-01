# Q2
## Resources
### Pre-Optimization
#### Plan
```
EXPLAIN: -> Filter: (Student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=5.44 rows=44) (actual time=0.106..2.766 rows=278 loops=1)
    -> Table scan on Student  (cost=5.44 rows=400) (actual time=0.092..2.399 rows=400 loops=1)
```
#### Profile
```
+----------+------------+-------------------------------------------------------+
| Query_ID | Duration   | Query                                                 |
+----------+------------+-------------------------------------------------------+
|        1 | 0.00415100 | SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3 |
+----------+------------+-------------------------------------------------------+
```
### Post-Optimization
#### Plan
```
*************************** 1. row ***************************
EXPLAIN: -> Filter: (Student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=56.47 rows=278) (actual time=0.100..1.085 rows=278 loops=1)
    -> Index range scan on Student using PRIMARY over (1145072 <= id <= 1828467)  (cost=56.47 rows=278) (actual time=0.091..0.905 rows=278 loops=1)
```
#### Profile
```
+----------+------------+-------------------------------------------------------+
| Query_ID | Duration   | Query                                                 |
+----------+------------+-------------------------------------------------------+
|        1 | 0.00262700 | SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3 |
+----------+------------+-------------------------------------------------------+
```
## What was the bottleneck?
The database had to scan the Student table to find rows between v2 and v3.

## How did you identify it?
I identified it by running `EXPLAIN ANALYZE` on the query.

## What method(s) did you use to resolve the bottleneck?
I added a primary key to the Student table
```
ALTER TABLE Student ADD CONSTRAINT PRIMARY KEY (id);
```
