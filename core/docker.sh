#!/usr/bin/env bash

########################################
# Docker Setup
#
# Ensures Docker and Docker Compose
# are installed and running.
########################################

DOCKER_INSTALLED=false
DOCKER_COMPOSE_AVAILABLE=false

########################################
# Ensure Docker is installed
########################################

ensure_docker() {

echo ""
echo "Checking Docker installation..."
echo ""

########################################
# Check docker binary
########################################

if command -v docker >/dev/null 2>&1; then

echo "Docker already installed."
DOCKER_INSTALLED=true

else

install_docker

fi

########################################
# Check docker compose plugin
########################################

if docker compose version >/dev/null 2>&1; then

echo "Docker Compose available."
DOCKER_COMPOSE_AVAILABLE=true

else

install_compose_plugin

fi

########################################
# Ensure Docker daemon running
########################################

if docker info >/dev/null 2>&1; then

echo "Docker daemon running."

else

start_docker

fi

}

########################################
# Install Docker
########################################

install_docker() {

echo "Installing Docker..."

if [ "$PACKAGE_MANAGER" = "apt" ]; then

apt update
apt install -y docker.io

else

echo "Unsupported package manager."
exit 1

fi

DOCKER_INSTALLED=true

}

########################################
# Install Docker Compose plugin
########################################

install_compose_plugin() {

echo "Installing Docker Compose plugin..."

if [ "$PACKAGE_MANAGER" = "apt" ]; then

apt install -y docker-compose-plugin

else

echo "Cannot install docker-compose-plugin automatically."
fi

DOCKER_COMPOSE_AVAILABLE=true

}

########################################
# Start Docker daemon
########################################

start_docker() {

echo "Starting Docker service..."

if [ "$SERVICE_MANAGER" = "systemd" ]; then

systemctl start docker
systemctl enable docker

elif [ "$SERVICE_MANAGER" = "sysvinit" ]; then

service docker start

else

echo "Unknown service manager."
fi

}