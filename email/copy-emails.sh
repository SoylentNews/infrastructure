#!/bin/bash

# Define the remote server details
REMOTE_USER="root"
REMOTE_HOST="72.14.184.41"
REMOTE_BASE_DIR="/var/vmail/soylentnews.org"

# Define the destination directory
DEST_DIR="/opt/mail/mailu/mail"

# Define the path to append
APPEND_PATH="@soylentnews.org"

# Get the list of folders from the remote directory
FOLDERS=$(ssh "$REMOTE_USER@$REMOTE_HOST" 'ls -d /var/vmail/soylentnews.org/*/' | xargs -n 1 basename)

# Loop through each folder and sync
for folder in $FOLDERS; do
    # Define the remote folder path
    remote_folder="$REMOTE_USER@$REMOTE_HOST:$REMOTE_BASE_DIR/$folder"
    # Define the local destination path with appended path
    local_dest="$DEST_DIR/${folder}$APPEND_PATH"
    # Use rsync to sync the folder
    rsync -av --progress "$remote_folder/" "$local_dest/"
    chown mail:man -R "$local_dest/"
done

