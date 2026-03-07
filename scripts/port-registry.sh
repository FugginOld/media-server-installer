#!/usr/bin/env bash

########################################
# Port Registry
#
# Maintains a registry of ports used by
# installed services to prevent conflicts.
########################################

STACK_DIR="/opt/media-stack"
PORT_FILE="$STACK_DIR/ports.json"

########################################
# Initialize port registry
########################################

init_port_registry() {

mkdir -p "$STACK_DIR"

if [ ! -f "$PORT_FILE" ]; then

cat <<EOF > "$PORT_FILE"
{
  "ports": {}
}
EOF

fi

}

########################################
# Register a port
########################################

register_port() {

SERVICE=$1
PORT=$2

init_port_registry

TMP_FILE=$(mktemp)

jq ".ports.\"$SERVICE\" = $PORT" "$PORT_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_FILE"

echo "Registered port $PORT for $SERVICE"

}

########################################
# Check if port is already used
########################################

is_port_in_use() {

PORT=$1

init_port_registry

jq -e ".ports | to_entries[] | select(.value == $PORT)" \
"$PORT_FILE" >/dev/null 2>&1

}

########################################
# Get port assigned to service
########################################

get_service_port() {

SERVICE=$1

init_port_registry

jq -r ".ports.\"$SERVICE\"" "$PORT_FILE"

}

########################################
# Remove service port
########################################

remove_port() {

SERVICE=$1

init_port_registry

TMP_FILE=$(mktemp)

jq "del(.ports.\"$SERVICE\")" "$PORT_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_FILE"

}