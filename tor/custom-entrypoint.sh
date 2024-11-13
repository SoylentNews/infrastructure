#!/bin/sh

/update-hosts.sh &
/docker-entrypoint.sh nginx -g 'daemon off;'
