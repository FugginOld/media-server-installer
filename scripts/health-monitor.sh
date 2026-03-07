#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"
LOG_FILE="$STACK_DIR/health-monitor.log"

INTERVAL=300

echo "Health monitor started." >> "$LOG_FILE"

while true
do

########################################
# Ensure compose file exists
########################################

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "$(date) Compose file missing." >> "$LOG_FILE"
    sleep "$INTERVAL"
    continue
fi

########################################
# Get unhealthy containers
########################################

UNHEALTHY=$(docker ps --filter "health=unhealthy" --format "{{.Names}}")

if [ -n "$UNHEALTHY" ]; then

echo "$(date) Unhealthy containers detected:" >> "$LOG_FILE"

for CONTAINER in $UNHEALTHY
do

echo "$(date) Restarting $CONTAINER" >> "$LOG_FILE"

docker restart "$CONTAINER"

done

fi

sleep "$INTERVAL"

done