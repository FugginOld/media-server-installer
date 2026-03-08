#!/usr/bin/env bash

########################################
# Media Stack Service Registry
#
# Maintains the services.json file used
# by dashboards and CLI commands.
########################################

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Initialize registry
########################################

init_registry() {

mkdir -p "$STACK_DIR"

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo '{"services":[]}' > "$SERVICE_REGISTRY"
fi

}

########################################
# Check if service exists
########################################

service_exists() {

NAME=$1

jq -e --arg name "$NAME" \
'.services[] | select(.name==$name)' \
"$SERVICE_REGISTRY" >/dev/null 2>&1

}

########################################
# Register service
########################################

register_service() {

NAME=$1
URL=$2
CATEGORY=$3
ICON=$4

init_registry

TMP_FILE=$(mktemp)

########################################
# Remove existing entry first
########################################

jq --arg name "$NAME" \
' .services |= map(select(.name != $name)) ' \
"$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

TMP_FILE=$(mktemp)

########################################
# Add updated service entry
########################################

jq --arg name "$NAME" \
   --arg url "$URL" \
   --arg category "$CATEGORY" \
   --arg icon "$ICON" \
'.services += [{
  name: $name,
  url: $url,
  category: $category,
  icon: $icon
}]' "$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

echo "Registered service: $NAME"

}

########################################
# Remove service
########################################

remove_service() {

NAME=$1

init_registry

TMP_FILE=$(mktemp)

jq --arg name "$NAME" \
'.services |= map(select(.name != $name))' \
"$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

echo "Removed service: $NAME"

}

########################################
# Get service URL
########################################

get_service_url() {

NAME=$1

init_registry

jq -r --arg name "$NAME" \
'.services[] | select(.name==$name) | .url' \
"$SERVICE_REGISTRY"

}

########################################
# List services
########################################

list_services() {

init_registry

jq .

}

########################################
# Pretty print services
########################################

pretty_services() {

init_registry

jq -r '.services[] |
"\(.name) -> \(.url)"' "$SERVICE_REGISTRY"

}