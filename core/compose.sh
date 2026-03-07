#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"

########################################
# NEW: Verify stack directory exists
########################################

if [ ! -d "$STACK_DIR" ]; then
echo "Media stack directory not found:"
echo "$STACK_DIR"
echo ""
echo "The stack may not be installed yet."
exit 1
fi

case "$1" in

up)
cd "$STACK_DIR"
docker compose up -d
;;

down)
cd "$STACK_DIR"
docker compose down
;;

restart)
cd "$STACK_DIR"
docker compose restart
;;

pull)
cd "$STACK_DIR"
docker compose pull
;;

logs)
cd "$STACK_DIR"
docker compose logs -f
;;

########################################
# NEW: Show container status
########################################

status)
cd "$STACK_DIR"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
;;

*)

echo "Usage: compose.sh [up|down|restart|pull|logs|status]"
;;

esac