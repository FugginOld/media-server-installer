#!/usr/bin/env bash

########################################
# Port Helper
# Used by plugins to safely assign ports
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

source "$INSTALL_DIR/scripts/port-registry.sh"

########################################
# Request a port mapping
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
# Register port
########################################

register_port "$SERVICE" "$HOST_PORT"

########################################
# Return compose format
########################################

echo "$HOST_PORT:$CONTAINER_PORT"

}

########################################
# Request multiple ports
########################################

get_multi_port_mapping() {

SERVICE="$1"
shift

PORTS=""

while [ $# -gt 0 ]; do

HOST_PORT="$1"
CONTAINER_PORT="$2"

register_port "$SERVICE-$HOST_PORT" "$HOST_PORT"

PORTS="$PORTS
      - \"$HOST_PORT:$CONTAINER_PORT\""

shift 2

done

echo "$PORTS"

}