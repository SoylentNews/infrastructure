#!/bin/sh

# Run the update-hosts.sh script in the background
/update-hosts.sh &
sleep 30
# Switch to irccatuser and run the irccat program
su -s /bin/sh irccatuser -c "/irccat"
