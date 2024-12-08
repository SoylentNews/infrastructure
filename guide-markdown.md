# Quick Start Guide to Docker DevOps Infrastructure

## Overview
This guide provides a comprehensive quick start for administrators to set up and manage our Docker-based DevOps infrastructure. The system leverages Docker and a host machine, with each service folder containing a `docker-compose.yml` file that defines the necessary services.

## Folder Structure
- **/opt/servicename**: This directory is used for persistent data storage for each service. Replace `servicename` with the actual name of the service.
- **/secrets/${ENVIRONMENT}.env**: This file contains environment-specific secrets. Replace `${ENVIRONMENT}` with the appropriate environment name (e.g., `production`, `staging`).
- **/secrets/${ENVIRONMENT}/${SERVICENAME}.env**: This file contains service-specific secrets for a given environment. Replace `${ENVIRONMENT}` with the environment name and `${SERVICENAME}` with the name of the service.

## Prerequisites
- **Docker**: Ensure Docker is installed and running on your host machine. You can download and install Docker from [here](https://www.docker.com/get-started).
- **Docker Compose**: Basic knowledge of Docker and Docker Compose is required. Docker Compose should also be installed. You can find the installation instructions [here](https://docs.docker.com/compose/install/).
- **Utility Scripts**: The scripts located in the `./util` directory should be added to your system's PATH. Run the `install-util.sh` script to achieve this. This script will ensure that the utility scripts are accessible from any location in your terminal.

## Setting Up Services

1. **Create Persistent Data Folder**:
   - Create a directory in `/opt/servicename` to store persistent data for each service. Replace `servicename` with the actual name of the service.
   - Ensure this folder is included in your backup script (`./backup.sh`) to maintain data integrity.

2. **Manage Secrets**:
   - Store environment-specific secrets in `/secrets/${ENVIRONMENT}/${SERVICENAME}.env`. Replace `${ENVIRONMENT}` with the appropriate environment name (e.g., `production`, `staging`) and `${SERVICENAME}` with the name of the service.
   - Reference these environment variables in your `docker-compose.yml` file to securely pass secrets to your services.

3. **Configure Docker Compose**:
   - Use volumes in your `docker-compose.yml` file to mount configuration files from `/opt/servicename/` to the appropriate locations within your containers.
   - Utilize Traefik labels in your `docker-compose.yml` file to map URLs to the corresponding service IPs and ports for proper routing.

4. **Template Replacement**:
   - Files with a `.template` extension will undergo string substitution, replacing placeholders like `{{ENV-VAR-NAME}}` with the corresponding environment variable values.
   - Use the `setup-env` script to set environment variables and run necessary hooks. The `dc` command will handle this process for you.

## Running Services
- **Start/Stop Services**:
  - Use `dc up` to start services.
  - Use `dc down` to stop services.
  - `dc` is an alias for `compose.sh`.

## Exiisting Services
- **/traefik: Web frontend and SSL proxy.
- **/rehash: Basic setup including MariaDB and Sphinx.
- **/rehash-dev**: Testing environment for rehash.
- **/ircd**: Solanum IRCD and Atheme services.

## Environment Setup Details from `compose.sh` and `setup-env.sh`

1. **Load Environment Variables**:
   - Environment variables are loaded from multiple sources in the following order of increasing priority:
     - `./.env`
     - `/secrets/${ENVIRONMENT}.env`
     - `/secrets/${ENVIRONMENT}/${SERVICENAME}.env`
     - `./.env` (loaded again to override any previous values)

2. **Execute Pre-Hook Script**:
   - The `pre-hook.sh` script is run to perform any necessary setup before processing templates. This can include tasks such as generating changes to the templates based on the environment variables.

3. **Process and Replace Templates**:
   - Templates are processed and filled with the appropriate values, including any secrets. Once filled, these templates are moved to the `/opt` directory.

4. **Execute Post-Hook Script**:
   - The `post-hook.sh` script is run to perform any final setup tasks before the Docker container is started. This typically involves moving secret-filled files from the devops home folder to the `/opt` directory to ensure they are in the correct location for the container.

## Commands

- **Start or Stop All Services**:
  - To start all services, use the following command:
    ```sh
    dc up
    ```
  - This command is equivalent to:
    ```sh
    docker compose up -d --force-recreate
    ```
  - It will start all services defined in the `docker-compose.yml` file in detached mode and recreate containers if necessary.

  - To stop all services, use the following command:
    ```sh
    dc down
    ```
  - This command is equivalent to:
    ```sh
    docker compose down
    ```
  - It will stop and remove all containers defined in the `docker-compose.yml` file.

- **Start or Stop a Specific Service**:
  - To start a specific service, use the following command:
    ```sh
    dc up [SERVICE_NAME] [EXTRA_ARGS]
    ```
  - This command is equivalent to:
    ```sh
    docker compose up --force-recreate "$SERVICE_NAME" $EXTRA_ARGS
    ```
  - Replace `[SERVICE_NAME]` with the name of the service you want to start and `[EXTRA_ARGS]` with any additional arguments.

  - To stop a specific service, use the following command:
    ```sh
    dc down [SERVICE_NAME] [EXTRA_ARGS]
    ```
  - This command is equivalent to:
    ```sh
    docker compose down --force-recreate "$SERVICE_NAME" $EXTRA_ARGS
    ```
  - Replace `[SERVICE_NAME]` with the name of the service you want to stop and `[EXTRA_ARGS]` with any additional arguments.
  

## Conclusion
This guide provides a structured approach to setting up and managing services in our Docker-based infrastructure. Follow the steps and examples to get started quickly.
