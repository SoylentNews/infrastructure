#!/bin/bash

# Run the backup script
/usr/local/bin/backup.sh

# Start supercronic
exec /usr/local/bin/supercronic /etc/crontab
