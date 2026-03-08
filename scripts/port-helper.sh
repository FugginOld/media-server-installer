#!/usr/bin/env bash

########################################
# Media Stack Port Helper
#
# Provides safe port allocation for
# plugins using the port registry.
########################################

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"
source "$INSTALL_DIR/scripts/port-registry.sh"

########################################
# Check if port currently in use on host
########################################

port_in_use_host() {

PORT=$1

ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$PORT$"

}

########################################
# Find next available port
########################################

find_next_available_port() {

PORT=$1

while true
do

# Check if port already registered
if port_registered "$PORT"; then
PORT=$((PORT + 1))
continue
fi

# Check if port used by host process
if port_in_use_host "$PORT"; then
PORT=$((PORT + 1))
continue
fi

echo "$PORT"
return

done

}

########################################
# Get port mapping for service
########################################

get_port_mapping() {

SERVICE=$1
DEFAULT_PORT=$2

init_port_registry

########################################
# Check if service already assigned
########################################

PORT=$(get_port "$SERVICE")

if [ -n "$PORT" ]; then
echo "$PORT"
return
fi

########################################
# Allocate port
########################################

PORT=$(find_next_available_port "$DEFAULT_PORT")

########################################
# Register port
########################################

register_port "$SERVICE" "$PORT"

echo "$PORT"

}