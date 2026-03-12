#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
#Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
#Initialize port registry
########################################

init_port_registry() {

mkdir -p "$(dirname "$PORT_REGISTRY")"

if [ ! -f "$PORT_REGISTRY" ]; then
echo "{}" > "$PORT_REGISTRY"
fi

}

########################################
#Validate port
########################################

validate_port() {

local PORT="$1"

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
echo "Invalid port: $PORT" >&2
exit 1
fi

if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
echo "Port out of range: $PORT" >&2
exit 1
fi

}

########################################
#Check if port already registered
########################################

port_registered() {

local PORT="$1"

jq -e --argjson port "$PORT" \
'to_entries[] | select(.value == $port)' \
"$PORT_REGISTRY" >/dev/null 2>&1

}

########################################
#Check if service already registered
########################################

service_registered() {

local SERVICE="$1"

jq -e --arg svc "$SERVICE" \
'has($svc)' \
"$PORT_REGISTRY" >/dev/null 2>&1

}

########################################
#Check if port is used on host
########################################

port_in_use() {

local PORT="$1"

ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$PORT$"

}

########################################
#Register port
########################################

register_port() {

local SERVICE="$1"
local PORT="$2"

init_port_registry
validate_port "$PORT"

if service_registered "$SERVICE"; then
echo "Service already has a port assigned: $SERVICE" >&2
exit 1
fi

if port_registered "$PORT"; then
echo "Port already registered: $PORT" >&2
exit 1
fi

if port_in_use "$PORT"; then
echo "Port already in use on host: $PORT" >&2
exit 1
fi

TMP_FILE="$(mktemp)"

jq --arg svc "$SERVICE" --argjson port "$PORT" \
'. + {($svc): $port}' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

echo "Registered port $PORT for $SERVICE"

}

########################################
#Remove port
########################################

remove_port() {

local SERVICE="$1"

init_port_registry

TMP_FILE="$(mktemp)"

jq --arg svc "$SERVICE" \
'del(.[$svc])' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

echo "Removed port assignment for $SERVICE"

}

########################################
#Get port for service
########################################

get_port() {

local SERVICE="$1"

init_port_registry

jq -r --arg svc "$SERVICE" \
'.[$svc] // empty' \
"$PORT_REGISTRY"

}

########################################
#Get service by port
########################################

get_service_by_port() {

local PORT="$1"

init_port_registry

jq -r --argjson port "$PORT" \
'to_entries[] | select(.value == $port) | .key' \
"$PORT_REGISTRY"

}

########################################
#List ports
########################################

list_ports() {

init_port_registry

jq . "$PORT_REGISTRY"

}

########################################
#Pretty list
########################################

pretty_ports() {

init_port_registry

jq -r '
to_entries[]
| "\(.key) -> \(.value)"
' "$PORT_REGISTRY"

}