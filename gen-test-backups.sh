
#!/bin/bash

# Directory to store the blank files
OUTPUT_DIR="/remote/backup-test"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate blank files for each hour over the past two months
for i in {0..1439}; do
    TIMESTAMP=$(date -d "$i hours ago" +"%F_%H:%M:%S")
    FILENAME="db_backup_${TIMESTAMP}.sql.qz.enc"
    touch "$OUTPUT_DIR/$FILENAME"
done

echo "Blank files for two months of hourlies have been generated."
