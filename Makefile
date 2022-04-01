mysql_cmd := mysql --defaults-file=/etc/mysql/debian.cnf
std_db := springboardstd
opt_db := springboardopt

all: init_std_db init_opt_db

.PHONY: init_std_db
init_std_db: populate_data.sql fix.sql
	$(mysql_cmd) -e "DROP DATABASE IF EXISTS $(std_db);"
	$(mysql_cmd) -e "CREATE DATABASE $(std_db);"
	$(mysql_cmd) $(std_db) < populate_data.sql
	$(mysql_cmd) $(std_db) < fix.sql

.PHONY: init_opt_db
init_opt_db: populate_data.sql fix.sql alter_schema.sql
	$(mysql_cmd) -e "DROP DATABASE IF EXISTS $(opt_db);"
	$(mysql_cmd) -e "CREATE DATABASE $(opt_db);"
	$(mysql_cmd) $(opt_db) < populate_data.sql
	$(mysql_cmd) $(opt_db) < fix.sql
	$(mysql_cmd) $(opt_db) < alter_schema.sql
