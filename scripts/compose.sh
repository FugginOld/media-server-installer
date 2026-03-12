#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

set -euo pipefail

########################################
#Load media-stack runtime environment
########################################


########################################
#Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
#Validate environment
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media Stack directory not found: $STACK_DIR"
exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
echo "docker-compose.yml missing in $STACK_DIR"
exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
echo "Docker is not installed."
exit 1
fi

########################################
#Change to stack directory
########################################

cd "$STACK_DIR"

########################################
#Command handler
########################################

COMMAND="${1:-help}"

case "$COMMAND" in

########################################
#Start containers
########################################

up)

echo "Starting Media Stack..."
docker compose up -d
;;

########################################
#Stop containers
########################################

down)

echo "Stopping Media Stack..."
docker compose down
;;

########################################
#Restart containers
########################################

restart)

echo "Restarting Media Stack..."
docker compose restart
;;

########################################
#Pull container updates
########################################

pull)

echo "Pulling container updates..."
docker compose pull
;;

########################################
#Logs
########################################

logs)

if [ -n "${2:-}" ]; then
docker compose logs -f "$2"
else
docker compose logs -f
fi
;;

########################################
#Container status
########################################

status)

docker compose ps
;;

########################################
#Validate compose config
########################################

validate)

docker compose config >/dev/null && echo "Compose file valid."
;;

########################################
#Invalid usage
########################################

*)

echo ""
echo "Media Stack Compose Controller"
echo ""
echo "Usage:"
echo "compose.sh up"
echo "compose.sh down"
echo "compose.sh restart"
echo "compose.sh pull"
echo "compose.sh logs [service]"
echo "compose.sh status"
echo "compose.sh validate"
echo ""
;;

esac