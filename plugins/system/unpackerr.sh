#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Automatic extraction for downloads used by Radarr and Sonarr"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=("radarr" "sonarr" "sabnzbd")

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=()
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Unpackerr..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/unpackerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  unpackerr:
    image: golift/unpackerr
    container_name: unpackerr
    networks:
      - media-network
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/unpackerr:/config
      - $DOWNLOADS_PATH:/downloads
EOF

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped

EOF

}