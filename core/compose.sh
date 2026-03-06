#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"

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

*)

echo "Usage: compose.sh [up|down|restart|pull|logs]"
;;

esac