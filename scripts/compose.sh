#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Ensure compose file exists
########################################

check_compose() {

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "docker-compose.yml not found."
    exit 1
fi

cd "$STACK_DIR" || exit

}

########################################
# Start stack
########################################

start_stack() {

check_compose

echo "Starting media stack..."

docker compose up -d

}

########################################
# Stop stack
########################################

stop_stack() {

check_compose

echo "Stopping media stack..."

docker compose down

}

########################################
# Restart stack
########################################

restart_stack() {

check_compose

echo "Restarting media stack..."

docker compose restart

}

########################################
# Update containers
########################################

pull_images() {

check_compose

echo "Updating container images..."

docker compose pull

}

########################################
# View logs
########################################

view_logs() {

check_compose

docker compose logs -f

}

########################################
# Show status
########################################

show_status() {

check_compose

docker compose ps

}

########################################
# Command routing
########################################

case "$1" in

up)
start_stack
;;

down)
stop_stack
;;

restart)
restart_stack
;;

pull)
pull_images
;;

logs)
view_logs
;;

status)
show_status
;;

*)

echo ""
echo "Usage: compose.sh [up|down|restart|pull|logs|status]"
echo ""

;;

esac