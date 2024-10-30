#!/bin/bash
source ./setup-env.sh
# Prefix all variables with LOADBACKUP_
LOADBACKUP_URL="${LOADBACKUP_URL}"
LOADBACKUP_ENCRYPTED_FILE="${LOADBACKUP_ENCRYPTED_FILE:-db-backup.gz.enc}"
LOADBACKUP_DECRYPTED_FILE="${LOADBACKUP_DECRYPTED_FILE:-db-backup.gz}"
LOADBACKUP_FINAL_FILE="${LOADBACKUP_FINAL_FILE:-db-backup.sql}"
LOADBACKUP_BACKUPDIR="${LOADBACKUP_BACKUPDIR:-/opt/rehash/backup}"

# Function to get the newest file in the directory
get_newest_file() {
    local dir=$1
    echo $(ls -t "$dir" | head -n 1)
}

# Ask if the user wants to use the default file
default_file=$(get_newest_file "$LOADBACKUP_BACKUPDIR")
read -p "Do you want to use the default file at $LOADBACKUP_BACKUPDIR/$default_file? (y/n): " use_default

if [[ "$use_default" == "y" ]]; then
    LOADBACKUP_URL="$LOADBACKUP_BACKUPDIR/$default_file"
else
    read -p "Enter the path or URL to the file: " LOADBACKUP_URL
fi

# Check if the path is an HTTP/HTTPS URL
if [[ "$LOADBACKUP_URL" =~ ^https?:// ]]; then
    # Download the file with progress bar
    curl -# -o "$LOADBACKUP_ENCRYPTED_FILE" "$LOADBACKUP_URL"
    downloaded=true
else
    # Copy the file from the given path
    cp "$LOADBACKUP_URL" "$LOADBACKUP_ENCRYPTED_FILE"
    downloaded=false
fi

# Use ENCRYPT_PASSWORD if set, otherwise prompt for the password
if [[ -z "$ENCRYPT_PASSWORD" ]]; then
    read -sp "Enter the decryption password: " password
    echo
else
    password="$ENCRYPT_PASSWORD"
fi

# Decrypt the file using a temporary file
openssl enc -d -aes-256-cbc -k "$password" -in "$LOADBACKUP_ENCRYPTED_FILE" -out "$LOADBACKUP_DECRYPTED_FILE"

# Remove the encrypted file copy
rm "$LOADBACKUP_ENCRYPTED_FILE"


# Decompress the decrypted file
gunzip -c "$LOADBACKUP_DECRYPTED_FILE" > "$LOADBACKUP_FINAL_FILE"

# Remove the temporary decrypted file
rm "$LOADBACKUP_DECRYPTED_FILE"

echo "File downloaded, decrypted, decompressed, and renamed to $LOADBACKUP_FINAL_FILE"



