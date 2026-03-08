#!/usr/bin/env bash

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

cat <<EOF > "$SERVICE_REGISTRY"
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
}]" "$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

echo "Registered service: $NAME"

}

########################################
# Remove service
########################################

remove_service() {

NAME=$1

TMP_FILE=$(mktemp)

jq "del(.services[] | select(.name == \"$NAME\"))" \
"$SERVICE_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$SERVICE_REGISTRY"

}

########################################
# List services
########################################

list_services() {

init_registry

cat "$SERVICE_REGISTRY"

}