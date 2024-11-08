#!/bin/sh

# useful script to call from the entrypoint of a container that needs to resolve irc.soylentnews.org to solanum
# could be generalized to resolve any public hostname to any internal service name later 

# Function to update /etc/hosts
update_hosts() {
    local ip=$1
    local hostname="irc.${BASE_URL}"
    local hosts_file="/etc/hosts"
    local temp_hosts_file="/etc/hosts.temp"

    # Check if the entry already exists
    if grep -q "$hostname" "$hosts_file"; then
        current_ip=$(grep "$hostname" "$hosts_file" | awk '{print $1}')
        if [ "$current_ip" != "$ip" ]; then
            echo "Updating $hostname from $current_ip to $ip"
            sed "s/^.*$hostname\$/$ip $hostname/" "$hosts_file" > "$temp_hosts_file"
            cat "$temp_hosts_file" > "$hosts_file"
        else
            echo "$hostname is already set to $ip, no update needed"
        fi
    else
        # Add a new entry
        echo "writing $ip to $hostname"
        echo "$ip $hostname" | tee -a "$hosts_file" > /dev/null
    fi
}

while true; do
    # Get the IP address of solanum
    ip=$(getent hosts solanum | awk '{ print $1 }')
    echo "solanum at $ip"
    if [ -n "$ip" ]; then
        update_hosts "$ip"
    else
        echo "Failed to resolve solanum"
    fi

    # Wait for 30 seconds before checking again
    sleep 30
done
