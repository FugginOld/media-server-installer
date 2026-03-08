#!/usr/bin/env bash

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Initialize port registry
########################################

init_port_registry() {

mkdir -p "$STACK_DIR"

if [ ! -f "$PORT_REGISTRY" ]; then

cat <<EOF > "$PORT_REGISTRY"
{}
EOF

fi

}

########################################
# Register port
########################################

register_port() {

SERVICE=$1
PORT=$2

init_port_registry

TMP_FILE=$(mktemp)

jq --arg svc "$SERVICE" --argjson port "$PORT" \
'. + {($svc): $port}' \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

echo "Registered port $PORT for $SERVICE"

}

########################################
# Remove port
########################################

remove_port() {

SERVICE=$1

TMP_FILE=$(mktemp)

jq "del(.\"$SERVICE\")" \
"$PORT_REGISTRY" > "$TMP_FILE"

mv "$TMP_FILE" "$PORT_REGISTRY"

}

########################################
# List ports
########################################

list_ports() {

init_port_registry

cat "$PORT_REGISTRY"

}