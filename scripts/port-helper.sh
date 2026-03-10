#!/usr/bin/env bash

########################################
# Media Stack Port Helper
#
# Provides safe port allocation for
# plugins using the port registry.
########################################

set -e

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"
source "$INSTALL_DIR/scripts/port-registry.sh"

########################################
# Check if port currently in use on host
########################################

port_in_use_host() {

local PORT=$1

ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$PORT$"

}

########################################
# Find next available port
########################################

find_next_available_port() {

local PORT=$1

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

# Port is safe
echo "$PORT"
return

done

}

########################################
# Get port mapping for service
########################################

get_port_mapping() {

local SERVICE=$1
local DEFAULT_PORT=$2

init_port_registry

########################################
# Check if service already assigned
########################################

local PORT
PORT=$(get_port "$SERVICE")

if [ -n "$PORT" ]; then
echo "$PORT"
return
fi

########################################
# Allocate next available port
########################################

PORT=$(find_next_available_port "$DEFAULT_PORT")

########################################
# Register port
########################################

register_port "$SERVICE" "$PORT"

echo "$PORT"

}