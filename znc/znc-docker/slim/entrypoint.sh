#!/bin/sh
/update-hosts.sh &
for f in /startup-sequence/*; do
    source "$f" || exit 1
done
