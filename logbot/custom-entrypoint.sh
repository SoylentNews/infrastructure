#!/bin/sh

# Start the background script
/update-hosts.sh &
sleep 3

# Export current environment variables
printenv | while IFS='=' read -r name value; do
  # Escape special characters and spaces
  value=$(printf '%s' "$value" | /bin/sed 's/"/\\"/g')
  export "$name=\"$value\""
done

# Run the python script as botuser with the current environment variables
sudo -E -u botuser python /loggie/logbot.py
