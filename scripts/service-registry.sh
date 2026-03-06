#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
REGISTRY_FILE="$STACK_DIR/services.json"

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

init_registry

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