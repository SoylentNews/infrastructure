# Check the value of ENVIRONMENT and load the appropriate environment file

if [ -f .env ]; then
    echo ".env overriding"
    export $(cat .env | xargs)
fi

if [ "$ENVIRONMENT" = "production" ]; then
    if [ -f /secrets/production.env ]; then
        echo "Loading from production.env"
        export $(cat /secrets/production.env | xargs)
    fi
else
    if [ -f /secrets/development.env ]; then
        echo "Loading from development.env"
        export $(cat /secrets/development.env | xargs)
    fi
fi

if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Load local .env file, overriding any variables from the secrets file
