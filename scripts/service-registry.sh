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
#Service Registry
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"

########################################
#Initialize registry
########################################

init_registry() {

mkdir -p "$(dirname "$SERVICE_REGISTRY")"

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo '{"services":[]}' > "$SERVICE_REGISTRY"
fi

}

########################################
#Register service
########################################

register_service() {

local NAME="$1"
local URL="$2"
local CATEGORY="$3"
local ICON="$4"

TMP_FILE="$(mktemp)"

########################################
#Remove existing service
########################################

jq \
--arg name "$NAME" \
'.services |= map(select(.name != $name))' \
"$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

########################################
#Add service entry
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

echo "Registered service: $NAME"

}