#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Request management for Plex"
PLUGIN_CATEGORY="automation"
PLUGIN_DEPENDS=("plex")

########################################
# Install Service
########################################

install_service() {

STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

echo "Installing Overseerr..."

########################################
# Ensure config directory exists
########################################

mkdir -p "$STACK_DIR/config/overseerr"

########################################
# Add container to compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  overseerr:
    image: lscr.io/linuxserver/overseerr:latest
    container_name: overseerr
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $STACK_DIR/config/overseerr:/config
    ports:
      - "5055:5055"
    restart: unless-stopped
    networks:
      - media-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5055"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register service in dashboard
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"

register_service \
"Overseerr" \
"http://localhost:5055" \
"Automation" \
"overseerr.png"

}
