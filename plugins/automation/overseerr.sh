#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Media request management for Plex"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("plex")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(5055)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Overseerr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/overseerr"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "overseerr" 5055 5055)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  overseerr:
    image: lscr.io/linuxserver/overseerr
    container_name: overseerr
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/overseerr:/config
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
      test: ["CMD", "curl", "-f", "http://localhost:5055"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Overseerr" \
"http://localhost:5055" \
"Automation" \
"overseerr.png"

}