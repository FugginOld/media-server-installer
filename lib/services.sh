#!/usr/bin/env bash

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

    init_registry

    URL="http://${HOST_IP}:${PORT}"

    TMP_FILE="$(mktemp)"

########################################
# Remove existing service entry
########################################

    jq \
    --arg name "$NAME" \
    '.services |= map(select(.name != $name))' \
    "$SERVICE_REGISTRY" > "$TMP_FILE"

    mv "$TMP_FILE" "$SERVICE_REGISTRY"

########################################
# Add service entry
########################################

    TMP_FILE="$(mktemp)"

    jq \
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
    "$SERVICE_REGISTRY" > "$TMP_FILE"

    mv "$TMP_FILE" "$SERVICE_REGISTRY"

    echo "Registered service: $NAME -> $URL"

########################################
# Regenerate dashboard automatically
########################################

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