#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="radarr"
PLUGIN_DESCRIPTION="Movie automation manager"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(7878)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Radarr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/radarr"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "radarr" 7878 7878)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  radarr:
    image: lscr.io/linuxserver/radarr
    container_name: radarr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/radarr:/config
      - $MOVIES_PATH:/movies
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
      test: ["CMD", "curl", "-f", "http://localhost:7878"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Radarr" \
"http://localhost:7878" \
"Automation" \
"radarr.png"

}