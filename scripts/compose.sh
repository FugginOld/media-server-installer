#!/usr/bin/env bash

########################################
# Docker Compose Controller
#
# Handles lifecycle management of the
# Media Stack containers.
########################################

STACK_DIR="/opt/media-stack"

########################################
# Verify stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media stack directory not found."
exit 1
fi

########################################
# Ensure compose file exists
########################################

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
echo "docker-compose.yml missing."
exit 1
fi

########################################
# Command handler
########################################

case "$1" in

########################################
# Start containers
########################################

up)

echo "Starting Media Stack..."

cd "$STACK_DIR"
docker compose up -d

;;

########################################
# Stop containers
########################################

down)

echo "Stopping Media Stack..."

cd "$STACK_DIR"
docker compose down

;;

########################################
# Restart containers
########################################

restart)

echo "Restarting Media Stack..."

cd "$STACK_DIR"
docker compose restart

;;

########################################
# Pull container updates
########################################

pull)

echo "Pulling container updates..."

cd "$STACK_DIR"
docker compose pull

;;

########################################
# Show container logs
########################################

logs)

cd "$STACK_DIR"
docker compose logs -f

;;

########################################
# Show container status
########################################

status)

cd "$STACK_DIR"
docker compose ps

;;

########################################
# Invalid usage
########################################

*)

echo ""
echo "Usage: compose.sh [up|down|restart|pull|logs|status]"
echo ""

;;

esac