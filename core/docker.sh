#!/usr/bin/env bash

########################################
# Docker configuration
########################################

STACK_DIR="/opt/media-stack"
NETWORK_NAME="media-network"

########################################
# Verify Docker service
########################################

check_docker() {

echo "Checking Docker service..."

if ! command -v docker >/dev/null 2>&1; then

echo "Docker is not installed."
echo "Please run install.sh first."

exit 1

fi

if ! systemctl is-active --quiet docker; then

echo "Starting Docker..."

systemctl start docker

fi

}

########################################
# Create docker network
########################################

create_docker_network() {

echo "Ensuring docker network exists..."

if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then

echo "Creating network: $NETWORK_NAME"

docker network create \
--driver bridge \
$NETWORK_NAME

else

echo "Docker network already exists"

fi

}

########################################
# Prepare stack directories
########################################

initialize_stack() {

mkdir -p $STACK_DIR
mkdir -p $STACK_DIR/config

}

########################################
# Deploy docker stack
########################################

deploy_stack() {

echo "Deploying docker containers..."

cd $STACK_DIR

docker compose up -d

}

########################################
# Display container status
########################################

show_stack_status() {

echo ""
echo "Running containers:"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

}

########################################
# Restart unhealthy containers
########################################

restart_unhealthy_containers() {

UNHEALTHY=$(docker ps --filter health=unhealthy --format "{{.Names}}")

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
# Docker cleanup
########################################

cleanup_docker() {

echo "Cleaning unused docker resources..."

docker container prune -f
docker image prune -f

}