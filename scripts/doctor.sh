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
  echo "Docker NOT installed."
fi

########################################
# Check Docker daemon
########################################

if docker info >/dev/null 2>&1; then
  echo "Docker daemon running."
else
  echo "Docker daemon NOT running."
fi

########################################
# Check docker compose
########################################

if docker compose version >/dev/null 2>&1; then
  echo "Docker Compose OK."
else
  echo "Docker Compose NOT available."
fi

########################################
# Check docker-compose.yml
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
  echo "docker-compose.yml present."
else
  echo "docker-compose.yml missing."
fi

########################################
# Check service registry
########################################

if [ -f "$STACK_DIR/services.json" ]; then
  echo "Service registry OK."
else
  echo "Service registry missing."
fi

########################################
# Check port registry
########################################

if [ -f "$STACK_DIR/ports.json" ]; then
  echo "Port registry OK."
else
  echo "Port registry missing."
fi

########################################
# Check running containers
########################################

echo ""
echo "Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Doctor check complete."
