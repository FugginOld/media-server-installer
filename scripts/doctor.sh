#!/usr/bin/env bash

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

if [ ! -d "$INSTALL_DIR" ]; then
echo "Installer directory missing:"
echo "$INSTALL_DIR"
exit 1
fi

echo "Installer directory OK."

########################################
# Check stack directory
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Stack directory missing:"
echo "$STACK_DIR"
exit 1
fi

echo "Stack directory OK."

########################################
# Check Docker
########################################

if ! command -v docker >/dev/null 2>&1; then
echo "Docker not installed."
exit 1
fi

echo "Docker installed."

########################################
# Check Docker daemon
########################################

if ! docker info >/dev/null 2>&1; then
echo "Docker daemon not running."
exit 1
fi

echo "Docker daemon running."

########################################
# Check docker compose file
########################################

if [ ! -f "$STACK_DIR/docker-compose.yml" ]; then
echo "docker-compose.yml missing."
exit 1
fi

echo "docker-compose.yml found."

########################################
# Check containers
########################################

echo ""
echo "Container status:"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

########################################
# Check service registry
########################################

REGISTRY="$STACK_DIR/services.json"

if [ -f "$REGISTRY" ]; then
echo ""
echo "Registered services:"
echo ""
jq -r '.services[] | "\(.name) -> \(.url)"' "$REGISTRY"
else
echo "Service registry not found."
fi

########################################
# Check plugin integrity
########################################

echo ""
echo "Validating plugins..."
echo ""

bash "$INSTALL_DIR/scripts/plugin-validator.sh"

echo ""
echo "Diagnostics complete."
echo ""