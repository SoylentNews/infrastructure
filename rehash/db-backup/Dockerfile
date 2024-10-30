FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    mysql-client \
    bash \
    gzip \
    openssl \
    curl

# Download supercronic
RUN curl -Lo /usr/local/bin/supercronic https://github.com/aptible/supercronic/releases/download/v0.1.11/supercronic-linux-amd64 && \
    chmod +x /usr/local/bin/supercronic

# Create a user and group with UID/GID 50000
RUN addgroup -g 50000 backupgroup && \
    adduser -D -u 50000 -G backupgroup backupuser

# Copy the backup script and entrypoint script into the container
COPY ./backup.sh /usr/local/bin/backup.sh
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

# Give execution rights on the scripts
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

# Create the cron job file
RUN echo "0 * * * * /usr/local/bin/backup.sh" > /etc/crontab

# Switch to the backupuser
USER backupuser

# Run the entrypoint script on container startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
