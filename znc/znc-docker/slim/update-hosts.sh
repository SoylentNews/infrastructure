#!/bin/sh

# Function to update /etc/hosts
update_hosts() {
    local ip=$1
    local hostname="irc.${BASE_URL}"
    local hosts_file="/etc/hosts"

    # Check if the entry already exists
    if grep -q "$hostname" "$hosts_file"; then
        # Update the existing entry
        sed -i "s/^.*$hostname\$/$ip $hostname/" "$hosts_file"
    else
        # Add a new entry
        echo "$ip $hostname" | tee -a "$hosts_file" > /dev/null
    fi
}

while true; do
    # Get the IP address of solanum
    ip=$(getent hosts solanum | awk '{ print $1 }')

    if [ -n "$ip" ]; then
        update_hosts "$ip"
    else
        echo "Failed to resolve solanum"
    fi

    # Wait for 30 seconds before checking again
    sleep 30
done
