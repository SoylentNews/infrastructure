#!/bin/sh

while true; do
    if ! pgrep -f "perl pisg" > /dev/null; then
        start_time=$(date +%s)
        echo "$(date): running pisg..."
        perl pisg &
        wait $!
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "$(date): finished running pisg. Time taken: ${elapsed_time} seconds."
    else
        echo "$(date): pisg is already running."
    fi
    sleep 1800  # Wait for 30 minutes
done
