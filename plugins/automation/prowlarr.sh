#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="prowlarr"
PLUGIN_DESCRIPTION="Indexer manager for the arr stack"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("radarr" "sonarr")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(9696)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Prowlarr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/prowlarr"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "prowlarr" 9696 9696)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  prowlarr:
    image: lscr.io/linuxserver/prowlarr
    container_name: prowlarr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/prowlarr:/config
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
      test: ["CMD", "curl", "-f", "http://localhost:9696"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Prowlarr" \
"http://localhost:9696" \
"Automation" \
"prowlarr.png"

}