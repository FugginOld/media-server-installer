#!/usr/bin/env bash

########################################
# Docker Variables
########################################

STACK_DIR="/opt/media-stack"
NETWORK_NAME="media-network"

########################################
# Ensure Docker is running
########################################

check_docker() {

echo "Checking Docker service..."

if ! systemctl is-active --quiet docker; then
    echo "Starting Docker..."
    systemctl start docker
fi

}

########################################
# Create Docker Network
########################################

create_docker_network() {

echo "Ensuring docker network exists..."

if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then

    echo "Creating network: $NETWORK_NAME"

    docker network create \
        --driver bridge \
        $NETWORK_NAME

else

    echo "Network already exists"

fi

}

########################################
# Initialize Compose Stack
########################################

initialize_stack() {

echo "Preparing docker stack..."

mkdir -p $STACK_DIR
mkdir -p $STACK_DIR/config

}

########################################
# Deploy Containers
########################################

deploy_stack() {

echo "Deploying docker containers..."

cd $STACK_DIR

docker compose up -d

}

########################################
# Show Running Containers
########################################

show_stack_status() {

echo ""
echo "Current container status:"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

}

########################################
# Restart Unhealthy Containers
########################################

restart_unhealthy_containers() {

echo "Checking for unhealthy containers..."

UNHEALTHY=$(docker ps --filter "health=unhealthy" --format "{{.Names}}")

if [ -z "$UNHEALTHY" ]; then

    echo "No unhealthy containers detected."

else

    echo "Restarting unhealthy containers..."

    for CONTAINER in $UNHEALTHY
    do
        docker restart $CONTAINER
    done

fi

}

########################################
# Cleanup Old Containers
########################################

cleanup_docker() {

echo "Cleaning unused Docker resources..."

docker container prune -f
docker image prune -f

}
