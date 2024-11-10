# Use the latest Alpine image
FROM alpine:latest

# Install Perl
RUN apk add --no-cache perl

# Create a non-root user with the specified UID and GID
RUN addgroup -g 50000 botgroup && \
    adduser -u 50000 -G botgroup -h /home/botuser -s /bin/sh -D botuser

# Copy the source code into the image
COPY src /home/botuser/src

# Set the working directory
WORKDIR /home/botuser/src

# Set file permissions
RUN chown -R botuser:botgroup /home/botuser/src

# Switch to the non-root user
USER botuser

# Run the bot script
CMD ["perl", "bot.v3.1.2.pl"]
