#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tdarr"
PLUGIN_DESCRIPTION="Distributed media transcoding system"
PLUGIN_CATEGORY="Media"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(8265)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Tdarr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create directories
########################################

mkdir -p "$CONFIG_DIR/tdarr/server"
mkdir -p "$CONFIG_DIR/tdarr/configs"
mkdir -p "$CONFIG_DIR/tdarr/logs"

########################################
# Reserve dashboard port
########################################

PORT_MAPPING=$(get_port_mapping "tdarr" 8265 8265)

########################################
# Compose container
########################################

cat <<EOF >> "$COMPOSE_FILE"

  tdarr:
    image: ghcr.io/haveagitgat/tdarr:latest
    container_name: tdarr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
      - "8266:8266"
    environment:
      - TZ=\${TIMEZONE}
      - serverIP=0.0.0.0
      - serverPort=8266
      - webUIPort=8265
    volumes:
      - $CONFIG_DIR/tdarr/server:/app/server
      - $CONFIG_DIR/tdarr/configs:/app/configs
      - $CONFIG_DIR/tdarr/logs:/app/logs
      - $MEDIA_PATH:/media
EOF

########################################
# GPU Support
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$COMPOSE_FILE"
fi

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$COMPOSE_FILE"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8265"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register Dashboard
########################################

register_service \
"Tdarr" \
"http://localhost:8265" \
"Media" \
"tdarr.png"

}