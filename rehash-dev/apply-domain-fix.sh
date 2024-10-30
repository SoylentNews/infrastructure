source ./setup-env.sh

# Get the current directory name
DOCKER_COMPOSE_NAME=$(basename "$PWD")

sed 's/{BASE_URL}/'$BASE_URL'/g' change-domain.sql | docker exec -i ${DOCKER_COMPOSE_NAME}-database-1 sh -c "cat - > /update-script.sql"
docker exec -i ${DOCKER_COMPOSE_NAME}-database-1 sh -c "mariadb -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} soylentnews < /update-script.sql"
