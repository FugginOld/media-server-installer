#!/usr/bin/env bash

########################################
# Port Registry
########################################

PORT_REGISTRY="$STACK_DIR/ports.json"

########################################
# Initialize registry
########################################

init_port_registry() {

mkdir -p "$(dirname "$PORT_REGISTRY")"

if [[ ! -f "$PORT_REGISTRY" ]]; then
echo "{}" > "$PORT_REGISTRY"
fi

}

########################################
# Check if port in use on host
########################################

port_in_use() {

local PORT="$1"

ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$PORT$"

}

########################################
# Check if port already registered
########################################

port_registered() {

local PORT="$1"

jq -e --argjson port "$PORT" \
'to_entries[] | select(.value == $port)' \
"$PORT_REGISTRY" >/dev/null 2>&1

}

########################################
# Find next available port
########################################

find_free_port() {

local START_PORT="${1:-20000}"
local PORT="$START_PORT"

while true; do

if ! port_in_use "$PORT" && ! port_registered "$PORT"; then
echo "$PORT"
return
fi

PORT=$((PORT + 1))

done

}

########################################
# Register port
########################################

register_port() {

local SERVICE="$1"
local DEFAULT_PORT="${2:-}"

init_port_registry

########################################
# If port already assigned, reuse it
########################################

EXISTING=$(jq -r --arg svc "$SERVICE" '.[$svc] // empty' "$PORT_REGISTRY")

if [[ -n "$EXISTING" ]]; then
echo "$EXISTING"
return
fi

########################################
# Try default port first
########################################

if [[ -n "$DEFAULT_PORT" ]]; then

if ! port_in_use "$DEFAULT_PORT" && ! port_registered "$DEFAULT_PORT"; then
PORT="$DEFAULT_PORT"
else
PORT=$(find_free_port 20000)
fi

else

PORT=$(find_free_port 20000)

fi

########################################
# Save port
########################################

TMP_FILE="$(mktemp)"

jq --arg svc "$SERVICE" --argjson port "$PORT" \
'. + {($svc): $port}' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

echo "$PORT"

}

########################################
# Get port for service
########################################

get_port() {

local SERVICE="$1"

init_port_registry

jq -r --arg svc "$SERVICE" \
'.[$svc] // empty' \
"$PORT_REGISTRY"

}

########################################
# Pretty print
########################################

pretty_ports() {

init_port_registry

jq -r '
to_entries[]
| "\(.key) -> \(.value)"
' "$PORT_REGISTRY"

}