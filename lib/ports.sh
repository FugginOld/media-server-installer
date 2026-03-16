#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
# Port registry
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
# Check if port in use
########################################

port_in_use() {
    local port="$1"

    # Use more specific ss output format
    if ss -tuln 2>/dev/null | awk -vp="$port" '$5 ~ ":"p"$" {found=1; exit 0} END {exit !found}'; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

########################################
# Find next free port
########################################

find_next_port() {

local PORT="$1"

while port_in_use "$PORT"
do
((PORT++))
done

echo "$PORT"

}

########################################
# Register port
########################################

register_port() {

local SERVICE="${1:-}"
local PORT="${2:-}"

if [[ -z "$SERVICE" ]]; then
echo "register_port: missing service name"
exit 1
fi

init_port_registry

if [[ -z "$PORT" ]]; then
echo ""
return
fi

########################################
# Automatic conflict resolution
########################################

if port_in_use "$PORT"; then

NEW_PORT=$(find_next_port "$PORT")

warn "Port $PORT already in use for $SERVICE"
log "Assigning next available port: $NEW_PORT"

PORT="$NEW_PORT"

fi

TMP_FILE="$(mktemp)"

jq --arg svc "$SERVICE" --argjson port "$PORT" \
'. + {($svc): $port}' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

echo "$PORT"

}

########################################
# Get port mapping
########################################

get_port_mapping() {

local SERVICE="${1:-}"
local DEFAULT_PORT="${2:-}"

if [[ -z "$SERVICE" ]]; then
echo ""
return
fi

init_port_registry

PORT=$(jq -r --arg svc "$SERVICE" '.[$svc] // empty' "$PORT_REGISTRY")

########################################
# Existing mapping
########################################

if [[ -n "$PORT" ]]; then
echo "$PORT"
return
fi

########################################
# Register default
########################################

if [[ -n "$DEFAULT_PORT" ]]; then
register_port "$SERVICE" "$DEFAULT_PORT"
else
echo ""
fi

}

########################################
# Backward compatibility wrapper
########################################

get_port() {

local SERVICE="${1:-}"
local DEFAULT_PORT="${2:-}"

get_port_mapping "$SERVICE" "$DEFAULT_PORT"

}

########################################
# Export functions
########################################

export -f init_port_registry
export -f register_port
export -f get_port_mapping
export -f get_port
export -f port_in_use
export -f find_next_port
