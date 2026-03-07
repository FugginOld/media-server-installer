#!/usr/bin/env bash

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

echo ""
echo "================================"
echo " Media Stack Doctor"
echo "================================"
echo ""

########################################
# Installer directory
########################################

if [ -d "$INSTALL_DIR" ]; then
    echo "Installer directory OK."
else
    echo "Installer directory missing."
fi

########################################
# Stack directory
########################################

if [ -d "$STACK_DIR" ]; then
    echo "Stack directory OK."
else
    echo "Stack directory missing."
fi

########################################
# Docker check
########################################

if command -v docker >/dev/null 2>&1; then
    echo "Docker installed."
else
    echo "Docker not installed."
fi

########################################
# Docker daemon
########################################

if docker info >/dev/null 2>&1; then
    echo "Docker daemon running."
else
    echo "Docker daemon not running."
fi

########################################
# Compose file
########################################

if [ -f "$COMPOSE_FILE" ]; then
    echo "docker-compose.yml found."
else
    echo "docker-compose.yml missing."
fi

########################################
# Containers running
########################################

if docker compose -f "$COMPOSE_FILE" ps >/dev/null 2>&1; then

RUNNING=$(docker compose -f "$COMPOSE_FILE" ps -q | wc -l)

echo "Containers detected: $RUNNING"

else

echo "Cannot read container status."

fi

########################################
# Service registry
########################################

if [ -f "$STACK_DIR/services.json" ]; then
    echo "Service registry OK."
else
    echo "services.json missing."
fi

########################################
# Port registry
########################################

if [ -f "$STACK_DIR/ports.json" ]; then
    echo "Port registry OK."
else
    echo "ports.json missing."
fi

echo ""
echo "Doctor check complete."
echo ""