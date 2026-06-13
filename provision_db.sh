#!/bin/bash
set -e

DB_USER=${DB_USER:-petclinic}
DB_PASS=${DB_PASS:-petclinic}
DB_NAME=${DB_NAME:-petclinic}

apt-get update -qq
apt-get install -y mysql-server


sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf


systemctl enable mysql
systemctl restart mysql



mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
mysql -e "FLUSH PRIVILEGES;"

echo "Встановлення MySQL завершено!"
