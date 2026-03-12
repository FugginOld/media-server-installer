#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Media Stack Port Helper
#
#Allocates and registers ports
#for plugins to prevent conflicts.
########################################

PORT_REGISTRY="$STACK_DIR/ports.json"

########################################
#Ensure jq exists
########################################

if ! command -v jq >/dev/null 2>&1; then
echo "jq is required for port management."
exit 1
fi

########################################
#Initialize port registry if missing
########################################

init_port_registry() {

mkdir -p "$(dirname "$PORT_REGISTRY")"

if [ ! -f "$PORT_REGISTRY" ]; then
echo "{}" > "$PORT_REGISTRY"
fi

}

########################################
#Check if port already used
########################################

port_in_use() {

local PORT="$1"

init_port_registry

jq -e --arg port "$PORT" '
to_entries[]
| select(.value.port == ($port|tonumber))
' "$PORT_REGISTRY" >/dev/null 2>&1

}

########################################
#Register port
########################################

register_port() {

local SERVICE="$1"
local PORT="$2"

init_port_registry

TMP_FILE="$(mktemp)"

jq \
--arg service "$SERVICE" \
--argjson port "$PORT" \
'.[$service] = {port:$port}' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

}

########################################
#Get port mapping
########################################

get_port_mapping() {

local SERVICE="$1"
local DEFAULT_PORT="$2"

local PORT="$DEFAULT_PORT"

########################################
#Increment until free
########################################

while port_in_use "$PORT"
do
PORT=$((PORT + 1))
done

########################################
#Register port
########################################

register_port "$SERVICE" "$PORT"

########################################
#Return port only
########################################

echo "$PORT"

}
