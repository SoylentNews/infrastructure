FROM debian:bullseye-slim

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user and group with specific UID and GID
RUN groupadd -g 50000 appgroup && \
    useradd -m -u 50000 -g appgroup appuser

# Create the hidden service directory and set ownership
RUN mkdir -p /var/lib/tor/hidden_service && \
    chown -R appuser:appgroup /var/lib/tor && \
    chown -R appuser:appgroup /etc/tor/

# Copy the script into the container
COPY run_commands.sh /usr/local/bin/run_commands.sh

# Make the script executable
RUN chmod +x /usr/local/bin/run_commands.sh

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/run_commands.sh"]

# Switch to the new user
USER appuser
