#!/usr/bin/env bash

########################################
# Port Helper
#
# Used by plugins to safely request
# port assignments from the registry.
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

source "$INSTALL_DIR/scripts/port-registry.sh"

########################################
# Request single port mapping
#
# Usage:
# PORT=$(get_port_mapping service host container)
########################################

get_port_mapping() {

SERVICE="$1"
HOST_PORT="$2"
CONTAINER_PORT="$3"

########################################
# Ensure registry exists
########################################

init_port_registry

########################################
# Check if port already assigned
########################################

if is_port_in_use "$HOST_PORT"; then

echo "Warning: port $HOST_PORT already registered."

fi

########################################
# Register port
########################################

register_port "$SERVICE" "$HOST_PORT"

########################################
# Return docker compose format
########################################

echo "$HOST_PORT:$CONTAINER_PORT"

}

########################################
# Request multiple ports
#
# Usage:
# get_multi_port_mapping service host1 cont1 host2 cont2 ...
########################################

get_multi_port_mapping() {

SERVICE="$1"
shift

PORT_BLOCK=""

while [ $# -gt 0 ]; do

HOST_PORT="$1"
CONTAINER_PORT="$2"

register_port "$SERVICE-$HOST_PORT" "$HOST_PORT"

PORT_BLOCK="$PORT_BLOCK
      - \"$HOST_PORT:$CONTAINER_PORT\""

shift 2

done

echo "$PORT_BLOCK"

}