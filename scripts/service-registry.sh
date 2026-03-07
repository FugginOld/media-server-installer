#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
REGISTRY_FILE="$STACK_DIR/services.json"

########################################
# NEW: Verify jq dependency
########################################

if ! command -v jq >/dev/null 2>&1; then
echo "jq is required for service registry."
exit 1
fi

########################################
# Initialize registry
########################################

init_registry() {

mkdir -p "$STACK_DIR"

if [ ! -f "$REGISTRY_FILE" ]; then

cat <<EOF > "$REGISTRY_FILE"
{
  "services": []
}
EOF

fi

}

########################################
# Register service
########################################

register_service() {

NAME=$1
URL=$2
CATEGORY=$3
ICON=$4

########################################
# NEW: Basic parameter validation
########################################

if [ -z "$NAME" ] || [ -z "$URL" ]; then
echo "register_service requires NAME and URL"
return
fi

init_registry

########################################
# NEW: Prevent duplicate service entries
########################################

EXISTS=$(jq -r ".services[] | select(.name==\"$NAME\") | .name" "$REGISTRY_FILE")

if [ "$EXISTS" = "$NAME" ]; then
echo "Service already registered: $NAME"
return
fi

TMP_FILE=$(mktemp)

jq ".services += [{
  \"name\": \"$NAME\",
  \"url\": \"$URL\",
  \"category\": \"$CATEGORY\",
  \"icon\": \"$ICON\"
}]" "$REGISTRY_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$REGISTRY_FILE"

echo "Registered service: $NAME"

}

########################################
# Remove service
########################################

remove_service() {

NAME=$1

########################################
# NEW: Ensure registry exists
########################################

init_registry

TMP_FILE=$(mktemp)

jq "del(.services[] | select(.name == \"$NAME\"))" \
"$REGISTRY_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$REGISTRY_FILE"

}

########################################
# List services
########################################

list_services() {

init_registry

cat "$REGISTRY_FILE"

}