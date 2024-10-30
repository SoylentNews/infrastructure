#!/bin/bash
source ./setup-env.sh
# Stop the Docker Compose container named rehash
docker compose stop rehash

# Get the container ID of the service named 'database'
container_id=$(docker compose ps -q database)

# Inspect the container to find the mount point
host_path=$(docker inspect "$container_id" \
    --format '{{ range .Mounts }}{{ if eq .Destination "/var/lib/mysql" }}{{ .Source }}{{ end }}{{ end }}')

# Get the Docker volume mount point
VOLUME_MOUNT_POINT=$host_path

# Move database.sql to the Docker volume folder with collation fix
sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' "$LOADBACKUP_FINAL_FILE"
sed -i 's/CHARSET=utf8mb4/CHARSET=utf8mb4/g' "$LOADBACKUP_FINAL_FILE"
sudo mv "$LOADBACKUP_FINAL_FILE" "$VOLUME_MOUNT_POINT/database.sql"

# Execute SQL script on MySQL database
docker compose exec database sh -c "mariadb -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} soylentnews < /var/lib/mysql/database.sql"
./apply-domain-fix.sh
docker compose start rehash
