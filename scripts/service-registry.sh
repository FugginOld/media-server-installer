#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Service Registry
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"

init_registry() {

mkdir -p "$STACK_DIR"

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo '{"services":[]}' > "$SERVICE_REGISTRY"
fi

}

register_service() {

NAME="$1"
URL="$2"
CATEGORY="$3"
ICON="$4"

TMP_FILE=$(mktemp)

########################################
# Remove existing service
########################################

jq \
--arg name "$NAME" \
'.services |= map(select(.name != $name))' \
"$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

########################################
# Add service entry
########################################

TMP_FILE=$(mktemp)

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

echo "Registered service: $NAME"

}
