#!/bin/bash
source /secrets/production.env
# Variables
LOCAL_BACKUP_DIR="/opt/rehash/backup/"
LOCAL_SECRETS_DIR="/secrets/"
REMOTE_USER="devops"
REMOTE_HOST=$REMOTE_BACKUP_HOST
REMOTE_BACKUP_DIR="/remote/backup/"
REMOTE_SECRETS_DIR="/remote/secrets/"
LOCKFILE="/tmp/backup.lock"


# Array of directories to copy
DIRECTORIES_TO_COPY=("/opt/atheme/" "/opt/ircd/")


# Extract IP and port from REMOTE_HOST
if [[ "$REMOTE_HOST" =~ ^([^:]+):([0-9]+)$ ]]; then
    REMOTE_IP="${BASH_REMATCH[1]}"
    SSH_PORT="${BASH_REMATCH[2]}"
else
    REMOTE_IP="$REMOTE_HOST"
    SSH_PORT=22
fi

if [ -e "$LOCKFILE" ]; then
    echo "Backup script is already running."
    exit 1
fi
trap "rm -f $LOCKFILE" EXIT
touch "$LOCKFILE"


# Sync /secrets/* to the remote host
rsync -avz -e "ssh -p $SSH_PORT" "$LOCAL_SECRETS_DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_SECRETS_DIR"

# Move files from /opt/rehash/backup/ to the remote host, keeping remote-only files
rsync -avz -e "ssh -p $SSH_PORT" "$LOCAL_BACKUP_DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_BACKUP_DIR"

# Check if rsync was successful
if [ $? -eq 0 ]; then
    echo "Backup and sync completed successfully."
else
    echo "Error during backup and sync."
fi

for DIR in "${DIRECTORIES_TO_COPY[@]}"; do
    if [ -d "$DIR" ]; then
        BASE_NAME=$(basename "$DIR")
        REMOTE_DIR="/remote/conf/$BASE_NAME/"
        echo "Copying $DIR to $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
        rsync -avz -e "ssh -p $SSH_PORT" "$DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
    else
        echo "Directory $DIR does not exist."
    fi
done
