#!/usr/bin/env bash

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"
source "$INSTALL_DIR/scripts/port-registry.sh"

########################################
# Check if port already in use
########################################

port_in_use() {

PORT=$1

if ss -tuln | grep -q ":$PORT "; then
    return 0
else
    return 1
fi

}

########################################
# Get port mapping for service
########################################

get_port_mapping() {

SERVICE=$1
DEFAULT_PORT=$2

init_port_registry

PORT=$(jq -r --arg svc "$SERVICE" '.[$svc]' "$PORT_REGISTRY")

########################################
# If service not yet assigned
########################################

if [ "$PORT" = "null" ]; then

PORT=$DEFAULT_PORT

########################################
# Avoid collisions
########################################

while port_in_use "$PORT"
do
    PORT=$((PORT + 1))
done

########################################
# Save to registry
########################################

register_port "$SERVICE" "$PORT"

fi

echo "$PORT"

}