#!/bin/bash

# Source the environment setup script
source ./setup-env.sh
./setup-env-file.sh

# Check if the first argument is 'up' or 'down'
COMMAND=$1
SERVICE_NAME=$2
shift 2  # Shift the first two arguments
EXTRA_ARGS="$@"  # Capture the remaining arguments

if [ "$COMMAND" == "up" ]; then
    if [ -n "$SERVICE_NAME" ]; then
        echo "Running docker compose up for service: $SERVICE_NAME"
        docker compose up -d --force-recreate "$SERVICE_NAME" $EXTRA_ARGS
    else
        echo "Running docker compose up for all services"
        docker compose up -d --force-recreate
    fi
elif [ "$COMMAND" == "down" ]; then
    if [ -n "$SERVICE_NAME" ]; then
        echo "Running docker compose down for service: $SERVICE_NAME"
        docker compose down "$SERVICE_NAME"
    else
        echo "Running docker compose down for all services"
        docker compose down
    fi
else
    echo "Invalid command. Use 'up' or 'down'."
    exit 1
fi
