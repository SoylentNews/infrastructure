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
