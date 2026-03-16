#!/usr/bin/env bash
set -euo pipefail

########################################
# Service Registry
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"

########################################
# Initialize registry
########################################

init_registry() {

    mkdir -p "$(dirname "$SERVICE_REGISTRY")"

    if [[ ! -f "$SERVICE_REGISTRY" ]]; then
        echo '{"services":[]}' > "$SERVICE_REGISTRY"
    fi

}

########################################
# Register service
########################################

register_service() {
    local NAME="$1"
    local PORT="$2"
    local CATEGORY="$3"
    local ICON="$4"

    # Validate inputs
    [[ -z "$NAME" ]] && { error "Service name required"; return 1; }
    [[ ! "$PORT" =~ ^[0-9]+$ ]] && { error "Invalid port: $PORT"; return 1; }

    init_registry

    # Check jq is available
    command -v jq >/dev/null || { error "jq not installed"; return 1; }

    local URL="http://${HOST_IP}:${PORT}"
    local TMP_FILE
    TMP_FILE="$(mktemp)" || { error "Failed to create temp file"; return 1; }
    trap 'rm -f "$TMP_FILE"' RETURN

    # Check if registry is valid JSON
    if ! jq empty "$SERVICE_REGISTRY" 2>/dev/null; then
        error "Service registry corrupted: $SERVICE_REGISTRY"
        return 1
    fi

    ########################################
    # Remove existing service entry
    ########################################

    if ! jq \
        --arg name "$NAME" \
        '.services |= map(select(.name != $name))' \
        "$SERVICE_REGISTRY" > "$TMP_FILE"; then
        error "Failed to remove existing service entry: $NAME"
        return 1
    fi

    # Verify output is valid JSON before moving
    if ! jq empty "$TMP_FILE" 2>/dev/null; then
        error "Generated invalid service registry during removal"
        return 1
    fi

    mv "$TMP_FILE" "$SERVICE_REGISTRY" || return 1

    ########################################
    # Add service entry
    ########################################

    TMP_FILE="$(mktemp)" || { error "Failed to create temp file"; return 1; }
    trap 'rm -f "$TMP_FILE"' RETURN

    if ! jq \
        --arg name "$NAME" \
        --arg url "$URL" \
        --arg category "$CATEGORY" \
        --arg icon "$ICON" \
        '.services += [{
            name:$name,
            url:$url,
            category:$category,
            icon:$icon
        }]' \
        "$SERVICE_REGISTRY" > "$TMP_FILE"; then
        error "Failed to add service entry: $NAME"
        return 1
    fi

    # Verify output is valid JSON before moving
    if ! jq empty "$TMP_FILE" 2>/dev/null; then
        error "Generated invalid service registry during addition"
        return 1
    fi

    mv "$TMP_FILE" "$SERVICE_REGISTRY" || return 1
    log "Registered service: $NAME -> $URL"
    if [[ -f "$INSTALL_DIR/scripts/dashboard-generator.sh" ]]; then
        bash "$INSTALL_DIR/scripts/dashboard-generator.sh" >/dev/null 2>&1 || true
    fi

}

########################################
# List services
########################################

list_services() {

    init_registry

    jq -r '.services[] | "\(.name) -> \(.url)"' "$SERVICE_REGISTRY"

}

########################################
# Pretty list for CLI
########################################

pretty_services() {

    init_registry

    jq -r '
    .services[]
    | "\(.name) -> \(.url)"
    ' "$SERVICE_REGISTRY"

}