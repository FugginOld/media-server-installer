#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle management for Radarr and Sonarr"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("radarr" "sonarr")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(6767)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Bazarr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/bazarr"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "bazarr" 6767 6767)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  bazarr:
    image: lscr.io/linuxserver/bazarr
    container_name: bazarr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/bazarr:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
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
      test: ["CMD", "curl", "-f", "http://localhost:6767"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Bazarr" \
"http://localhost:6767" \
"Automation" \
"bazarr.png"

}