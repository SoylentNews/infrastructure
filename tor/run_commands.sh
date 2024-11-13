#!/bin/bash

# Create the hidden service directory
mkdir -p /var/lib/tor/hidden_service

# Decode the environment variables and write them to the appropriate files
echo $SECRET_KEY | base64 -d > /var/lib/tor/hidden_service/hs_ed25519_secret_key
echo $PUBLIC_KEY | base64 -d > /var/lib/tor/hidden_service/hs_ed25519_public_key
echo $HOSTNAME | base64 -d > /var/lib/tor/hidden_service/hostname

# Set permissions for the hidden service directory and files
chown -R appuser:appgroup /var/lib/tor/hidden_service/
chmod 700 /var/lib/tor/hidden_service/
chmod 600 /var/lib/tor/hidden_service/hostname
chmod 600 /var/lib/tor/hidden_service/hs_ed25519_public_key
chmod 600 /var/lib/tor/hidden_service/hs_ed25519_secret_key

# Write the tor configuration
echo "HiddenServiceDir /var/lib/tor/hidden_service/" > /etc/tor/torrc
echo "HiddenServicePort 80 nginx:80" >> /etc/tor/torrc

# Output the hostname and start tor
(cat /var/lib/tor/hidden_service/hostname || echo "No hostname found.") && tor -f /etc/tor/torrc

