#!/bin/sh

##### CONFIGURE HERE
USERNAME="username"
PASSWORD="password"
BBDD="database"
DB_PASS="sql-password"
####

echo "I will create user '${USERNAME}' and database '${BBDD}'"
echo -n "Press ENTER to continue or CTRL+C to quit."
read pause

### create BBDD
echo "Create BBDD: ${BBDD}"
mysqladmin -u root -p${DB_PASS} create ${BBDD}

### create user
echo "Create USER: ${USERNAME}"
QUERY="CREATE USER '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}';"
mysql -u root -p${DB_PASS} -e "$QUERY"

### create privs
echo "Create PRIVILEGES"
QUERY="GRANT ALL PRIVILEGES ON ${BBDD}.* TO '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;";
mysql -u root -p${DB_PASS} -e "$QUERY"
QUERY="GRANT ALL PRIVILEGES ON ${BBDD}.* TO '${USERNAME}'@'localhost' IDENTIFIED BY '${PASSWORD}' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;";
mysql -u root -p${DB_PASS} -e "$QUERY"

echo "Flush PRIVILEGES"
QUERY="FLUSH PRIVILEGES;"
mysql -u root -p${DB_PASS} -e "$QUERY"

echo "DONE!"

