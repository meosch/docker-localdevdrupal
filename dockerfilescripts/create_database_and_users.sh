#!/bin/bash

set -e

/usr/bin/mysqld_safe > /dev/null 2>&1 &

# Wait until Mysql is up
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

#
#DATABASES=("database1" "database2")
#declare -A USERS=(["user1"]="pass1" ["user2"]="pass2")
#ADMINS=("user1")

DATABASES=("drupal")
declare -A USERS=(["drupal"]="drupalrocks")
ADMINS=("drupal")

# Create databases
for DB in ${DATABASES[*]}; do
    mysql -uroot -e "CREATE DATABASE $DB;"
done

# Create users and grant in created databases
for USER in "${!USERS[@]}"; do
    PASS=${USERS["$USER"]}

    mysql -uroot -e "CREATE USER '$USER'@'%' IDENTIFIED BY '$PASS';"
    for DB in $DATABASES; do
        mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'%';"
    done
done

for ADMIN in "${ADMINS[*]}"; do
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$ADMIN'@'%';"
done

# Delete @localhost user to allow our users to access localhost
# http://serverfault.com/questions/122472/allowing-wildcard-access-on-mysql-db-getting-error-access-denied-for-use
mysql -uroot -e "USE mysql;DELETE FROM mysql.user WHERE user='' AND host='localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"

mysqladmin -uroot shutdown
