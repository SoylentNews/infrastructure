#!/bin/bash

# Set MySQL credentials
#MYSQL_USER="your_user"
#MYSQL_PASSWORD="your_password"
#MYSQL_HOST="mysql_container"
#MYSQL_DB="your_database"
#ENCRYPT_PASSWORD="password"

# Set backup directory
BACKUP_DIR="/backup"
mkdir -p $BACKUP_DIR

# Create a timestamp
TIMESTAMP=$(date +"%F_%T")

# Perform the backup
mysqldump -h $MYSQL_HOST --lock-tables=false -u $MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DB | gzip | openssl enc -aes-256-cbc -e -out  $BACKUP_DIR/db_backup_$TIMESTAMP.sql.qz.enc -pass pass:$ENCRYPT_PASSWORD

# Optional: Remove old backups (e.g., older than 5 hours)
find $BACKUP_DIR -type f -name "*.sql.qz.enc" -mmin +300 -exec rm {} \;
