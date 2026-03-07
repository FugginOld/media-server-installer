#!/usr/bin/env bash

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
# Check if port is already used
########################################

port_in_use() {

PORT=$1

ss -tuln | grep -q ":$PORT "

}

########################################
# Register port
########################################

register_port() {

SERVICE=$1
PORT=$2

init_port_registry

########################################
# Check registry
########################################

if jq -e ".ports.\"$SERVICE\"" "$PORT_FILE" >/dev/null; then

echo "Port already reserved for $SERVICE"

return

fi

########################################
# Prevent conflicts
########################################

if jq -e ".ports[] | select(. == $PORT)" "$PORT_FILE" >/dev/null; then

echo "Port conflict detected: $PORT"
exit 1

fi

########################################
# Prevent host conflicts
########################################

if port_in_use "$PORT"; then

echo "Port already in use on host: $PORT"
exit 1

fi

TMP_FILE=$(mktemp)

jq ".ports.\"$SERVICE\" = $PORT" "$PORT_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_FILE"

echo "Reserved port $PORT for $SERVICE"

}

########################################
# Get port mapping
########################################

get_port_mapping() {

SERVICE=$1
HOST_PORT=$2
CONTAINER_PORT=$3

register_port "$SERVICE" "$HOST_PORT"

echo "$HOST_PORT:$CONTAINER_PORT"

}