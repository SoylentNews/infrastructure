#!/bin/bash
# exit 0
source /secrets/production.env
# Variables
LOCAL_BACKUP_DIR="/opt/rehash/backup/"
LOCAL_BACKUP_DIR_DEV="/opt/rehash-dev/backup/"
LOCAL_SECRETS_DIR="/secrets/"
REMOTE_USER="devops"
REMOTE_HOST=$REMOTE_BACKUP_HOST
REMOTE_BACKUP_DIR="/home/remote/backup/"
REMOTE_BACKUP_DIR_DEV="/home/remote/backup-dev/"
REMOTE_SECRETS_DIR="/home/remote/secrets/"
LOCKFILE="/tmp/backup.lock"


# Array of directories to copy
declare -A DIRECTORIES_TO_COPY=(
    ["/opt/atheme/"]="atheme/"
    ["/opt/ircd/"]="ircd/"
    ["/opt/loggie/"]="loggie/"
    ["/opt/eggbot/"]="eggbot/"
    ["/opt/mail/mailu/"]="mailu/"
    ["/opt/bender/"]="bender/"
    ["/opt/irpg/"]="irpg/"
    ["/opt/dns/backup/"]="pdns-db/"
    ["/opt/mediawiki/images/"]="mediawiki-img/"
    ["/opt/mediawiki/backup/"]="mediawiki-db/"
    ["/opt/tor/"]="tor/"
    ["/opt/znc/data/"]="znc/"
    ["/opt/hc/"]="hc/"
    ["/opt/lg/"]="lg/"
)


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
sudo rsync -avz -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" "$LOCAL_SECRETS_DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_SECRETS_DIR"

# Move files from /opt/rehash/backup/ to the remote host, keeping remote-only files
sudo rsync -avz -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" "$LOCAL_BACKUP_DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_BACKUP_DIR"

sudo rsync -avz --delete -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" "$LOCAL_BACKUP_DIR_DEV" "$REMOTE_USER@$REMOTE_IP:$REMOTE_BACKUP_DIR_DEV"


# Check if rsync was successful
if [ $? -eq 0 ]; then
    echo "Backup and sync completed successfully."
else
    echo "Error during backup and sync."
fi

for DIR in "${!DIRECTORIES_TO_COPY[@]}"; do
    REMOTE_RELATIVE_PATH="${DIRECTORIES_TO_COPY[$DIR]}"
    if [ -d "$DIR" ]; then
        REMOTE_DIR="/home/remote/conf/$REMOTE_RELATIVE_PATH"
        echo "Copying $DIR to $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
        sudo rsync -avz -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" "$DIR" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
    else
        echo "Directory $DIR does not exist."
    fi
done

curl --insecure -m 10 --retry 5 https://hc.soylentnews.org/ping/daacd67f-ae6c-4613-9d62-92e1b0601b10
