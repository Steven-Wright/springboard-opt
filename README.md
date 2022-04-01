# SQL Optimization 

## Setup
I used a linux container running on a [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) as my development environment.

### lxd setup
Since I used Raspberry Pi OS Lite I had to install snapd:
```sudo apt install snapd```

Then I installed core and lxd snaps:
```
sudo snap install core
sudo snap install lxd
```

After a restart I ran the lxd init and added the default user to the lxd group:
```
sudo /snap/bin/lxd init
sudo usermod -aG lxd pi
```

Finally I launched an ubuntu container and pushed the project files
```
lxc launch images:ubuntu/20.04 container
lxc file push ~/q{1,2,3,4,5,6}.sql container/root/
lxc exec container -- /bin/bash
```

### container setup
I installed mysql and nano from using apt:
```apt install nano mysql-server```

Finally, I loaded the data using the provided `populate_data.sql` file:
mysql  --defaults-file=/etc/mysql/debian.cnf < populate_data.sql

## Data issues

### Course.crsCode isn't unique
The Course table contains information about an individual course which is referenced in other tables by a crsCode, it should be unique.

#### Fix
```
DELETE FROM Course WHERE crsCode = 'MGT157' AND crsName LIKE 'Human Robot%';
DELETE FROM Course WHERE crsCode = 'MGT382' AND crsName LIKE 'Introduction%';
DELETE FROM Course WHERE crsCode = 'EE820' AND crsName LIKE 'System Security%';
```

### Teaching and Transcript don't share keys
One might expect there to be some rows in both tables with the same crcCode and semester, but this isn't the case.
```
mysql> SELECT COUNT(*) FROM Teaching JOIN Transcript USING (crsCode, semester);
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set (0.01 sec)
```

#### Fix
```
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
```

## Optimizations based on database schema
RDBMs generally perform better when they are provided with any available constraints on teach table and column.

From `populate_data.sql`:
```
CREATE TABLE Student (
    id INT,
    name VARCHAR(255),
    address VARCHAR(255),
    status VARCHAR(255)
);

CREATE TABLE Professor (
    id INT,
    name VARCHAR(255),
    deptId VARCHAR(255)
);

CREATE TABLE Course (
    crsCode VARCHAR(255),
    deptId VARCHAR(255),
    crsName VARCHAR(255)
);

CREATE TABLE Teaching (
    crsCode VARCHAR(255),
    semester VARCHAR(255),
    profId INT
);

CREATE TABLE Transcript (
    studId INT,
    crsCode VARCHAR(255),
    semester VARCHAR(255),
    grade VARCHAR(255)
);
```

#### Primary keys
Right of the bat it would seem like a good idea to add primary keys to tables that will be referenced by other tables. 
- Student(id)
- Professor(id)
- Course(crsCode)

#### NOT NULL constraint
Null values in the associative tables Teaching and Transcript don't make sense and the possibility of NULL values can cause an extra filtering step when preforming joins.
- Teaching(crsCode)
- Teaching(semester)
- Teaching(profId)
- Transcript(studId)
- Transcript(crsCode)
- Transcript(semester)
