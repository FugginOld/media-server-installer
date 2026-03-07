#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="sonarr"
PLUGIN_DESCRIPTION="TV series automation manager"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(8989)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Sonarr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/sonarr"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "sonarr" 8989 8989)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  sonarr:
    image: lscr.io/linuxserver/sonarr
    container_name: sonarr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/sonarr:/config
      - $TV_PATH:/tv
      - $DOWNLOADS_PATH:/downloads
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
      test: ["CMD", "curl", "-f", "http://localhost:8989"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Sonarr" \
"http://localhost:8989" \
"Automation" \
"sonarr.png"

}