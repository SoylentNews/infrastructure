IRC_CERT_DOMAIN=irc.${BASE_URL}
if [ -f "/data/certs/certs/${IRC_CERT_DOMAIN}.crt" ]; then
	if [ -f "/data/certs/certs/solanum.crt" ]; then
		rm "/data/certs/certs/solanum.crt"
	fi
	cp "/data/certs/certs/${IRC_CERT_DOMAIN}.crt" /data/certs/certs/solanum.crt
        chown 50000:50000 /data/certs/certs/solanum.crt
fi

if [ -f "/data/certs/private/${IRC_CERT_DOMAIN}.key" ]; then
	if [ -f "/data/certs/private/solanum.key" ]; then
		rm "/data/certs/private/solanum.key"
	fi
	cp "/data/certs/private/${IRC_CERT_DOMAIN}.key" /data/certs/private/solanum.key
        chown 50000:50000 /data/certs/private/solanum.key
fi

CERT_PATH="/data/certs/certs/${IRC_CERT_DOMAIN}.crt"
KEY_PATH="/data/certs/private/${IRC_CERT_DOMAIN}.key"
ZNC_CERT_PATH="/data/certs/certs/znc-cert.pem"
ZNC_KEY_PATH="/data/certs/private/znc-key.pem"
ZNC_DHPARAM_PATH="/data/certs/certs/znc-dhparam.pem"

# Check if the certificate and key files exist
if [[ -f "$CERT_PATH" && -f "$KEY_PATH" ]]; then
    echo "Certificate and key files exist."

    # Remove existing znc files if they exist
    if [[ -f "$ZNC_CERT_PATH" ]]; then
        rm "$ZNC_CERT_PATH"
        echo "Removed $ZNC_CERT_PATH"
    fi

    if [[ -f "$ZNC_KEY_PATH" ]]; then
        rm "$ZNC_KEY_PATH"
        echo "Removed $ZNC_KEY_PATH"
    fi

    if [[ -f "$ZNC_DHPARAM_PATH" ]]; then
        rm "$ZNC_DHPARAM_PATH"
        echo "Removed $ZNC_DHPARAM_PATH"
    fi

    # Copy the new certificate and key files
    cp "$CERT_PATH" "$ZNC_CERT_PATH"
    cp "$KEY_PATH" "$ZNC_KEY_PATH"
    echo "Copied new certificate and key files to ZNC paths."

    # Generate Diffie-Hellman parameters
    openssl dhparam -out "$ZNC_DHPARAM_PATH" 2048
    echo "Generated Diffie-Hellman parameters."

    # Change ownership of the new files to 50000:50000
    chown 50000:50000 "$ZNC_CERT_PATH" "$ZNC_KEY_PATH" "$ZNC_DHPARAM_PATH"
    echo "Changed ownership of the new files to 50000:50000."
else
    echo "Certificate and/or key files do not exist."
fi
