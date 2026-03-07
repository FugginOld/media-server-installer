#!/usr/bin/env bash

########################################
# Media Stack Doctor
#
# Diagnoses installation problems
# and verifies required components.
########################################

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"

echo ""
echo "================================"
echo " Media Stack Doctor"
echo "================================"
echo ""

########################################
# Check installer directory
########################################

if [ -d "$INSTALL_DIR" ]; then
echo "Installer directory OK."
else
echo "Installer directory missing."
fi

########################################
# Check stack directory
########################################

if [ -d "$STACK_DIR" ]; then
echo "Stack directory OK."
else
echo "Stack directory missing."
fi

########################################
# Check Docker installation
########################################

if command -v docker >/dev/null 2>&1; then
echo "Docker installed."
else
echo "Docker not installed."
fi

########################################
# Check Docker daemon
########################################

if docker info >/dev/null 2>&1; then
echo "Docker daemon running."
else
echo "Docker daemon not running."
fi

########################################
# Check compose file
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
echo "docker-compose.yml found."
else
echo "docker-compose.yml missing."
fi

########################################
# List containers
########################################

echo ""
echo "Running containers:"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""