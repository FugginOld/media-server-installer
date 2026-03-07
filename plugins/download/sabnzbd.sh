#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="sabnzbd"
PLUGIN_DESCRIPTION="Usenet downloader"
PLUGIN_CATEGORY="Download"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(8080)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing SABnzbd..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/sabnzbd"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "sabnzbd" 8080 8080)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd
    container_name: sabnzbd
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/sabnzbd:/config
      - $DOWNLOADS_PATH:/downloads
      - $DOWNLOADS_PATH/incomplete:/incomplete
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
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"SABnzbd" \
"http://localhost:8080" \
"Download" \
"sabnzbd.png"

}