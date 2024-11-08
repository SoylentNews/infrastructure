# Use an official Perl runtime as a parent image
FROM perl:latest

# Set environment variables
ENV PISG_COMMIT=c0d38ca

# Create a group and user with specific UID and GID
RUN groupadd -g 50000 pisg && \
    useradd -m -u 50000 -g pisg pisg

# Create the /usr/app directory and set permissions
RUN mkdir -p /usr/app && chown pisg:pisg /usr/app

# Copy the entrypoint script into the container and make it executable
COPY entrypoint.sh /usr/app/entrypoint.sh
RUN chmod +x /usr/app/entrypoint.sh && chown pisg:pisg /usr/app/entrypoint.sh

# Switch to the new user
USER pisg

# Set the working directory
WORKDIR /usr/app

# Clone the PISG repository into a temporary directory and checkout the specific commit
RUN git clone https://github.com/PISG/pisg.git /tmp/pisg && \
    cd /tmp/pisg && \
    git checkout ${PISG_COMMIT} && \
    cp -r /tmp/pisg/* /usr/app/ && \
    rm -rf /tmp/pisg

# Install any dependencies if needed (example)
# RUN cpanm --installdeps .

# Command to run when the container starts
CMD ["./entrypoint.sh"]
