#!/bin/bash

# Directory containing the backups
BACKUP_DIR="/home/remote/backup/"

if [[ "$#" -gt 0 && "$1" != "--dry-run" ]]; then
    BACKUP_DIR=$1
    shift
fi

# Flag to control dry run mode
DRY_RUN=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Function to handle file actions
handle_file() {
    local action=$1
    local file=$2
    local reason=$3
    if $DRY_RUN; then
        echo "$action: $file ($reason)"
    else
        if [ "$action" == "KEEP" ]; then
            echo "Keeping: $file ($reason)"
        elif [ "$action" == "DELETE" ]; then
            rm -f "$file"
            echo "Deleted: $file"
        fi
    fi
}

# Get the current date and time
CURRENT_DATE=$(date +"%F_%T")
CURRENT_TIMESTAMP=$(date +%s)

# Initialize associative arrays to track the latest files
declare -A latest_monthly latest_daily latest_hourly

# Find all backup files and process them
find "$BACKUP_DIR" -name "db_backup_*.sql.qz.enc" | sort -r | while read file; do
    # Extract the timestamp from the filename
    FILENAME=$(basename "$file")
    TIMESTAMP=$(echo "$FILENAME" | grep -oP '\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}')
    
    # Debugging output
    # echo "Processing file: $file"
    # echo "Extracted TIMESTAMP: $TIMESTAMP"
    
    if [ -z "$TIMESTAMP" ]; then
        echo "Invalid timestamp extracted from filename: $FILENAME"
        continue
    fi

    # Convert the timestamp to seconds since epoch
    TIMESTAMP_CORRECTED=$(echo "$TIMESTAMP" | sed 's/_/ /')
    FILE_DATE=$(date -d "$TIMESTAMP_CORRECTED" +%s 2>/dev/null)

    # Check if the date conversion was successful
    if [ -z "$FILE_DATE" ]; then
        echo "Invalid date format: $TIMESTAMP"
        echo "TIMESTAMP_CORRECTED: $TIMESTAMP_CORRECTED"
        continue
    fi

    # Determine the year, month, and day
    YEAR=$(echo "$TIMESTAMP" | cut -d'-' -f1)
    MONTH=$(echo "$TIMESTAMP" | cut -d'-' -f1-2)
    DAY=$(echo "$TIMESTAMP" | cut -d'-' -f1-3 | cut -d'_' -f1)

    # Check if the file is within the last 30 days
    if (( (CURRENT_TIMESTAMP - FILE_DATE) <= 2592000 )); then
        # Check if the file is within the last 24 hours
        if (( (CURRENT_TIMESTAMP - FILE_DATE) <= 86400 )); then
            latest_hourly["$TIMESTAMP"]="$file"
            handle_file "KEEP" "$file" "hourly"
        else
            if [[ -z "${latest_daily[$DAY]}" ]]; then
                latest_daily["$DAY"]="$file"
                handle_file "KEEP" "$file" "daily"
            else
                handle_file "DELETE" "$file" "not needed"
            fi
        fi
    else
        if [[ -z "${latest_monthly[$MONTH]}" ]]; then
            latest_monthly["$MONTH"]="$file"
            handle_file "KEEP" "$file" "monthly"
        else
            handle_file "DELETE" "$file" "not needed"
        fi
    fi
done

echo "Backup cleanup completed."
