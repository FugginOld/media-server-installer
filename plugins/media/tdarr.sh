#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tdarr"
PLUGIN_DESCRIPTION="Distributed transcoding and media processing"
PLUGIN_CATEGORY="media"
PLUGIN_DEPENDS=()

########################################
# Install Service
########################################

install_service() {

STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

echo "Installing Tdarr..."

########################################
# Ensure config directories exist
########################################

mkdir -p "$STACK_DIR/config/tdarr/server"
mkdir -p "$STACK_DIR/config/tdarr/configs"
mkdir -p "$STACK_DIR/config/tdarr/logs"

########################################
# Add container to compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  tdarr:
    image: ghcr.io/haveagitgat/tdarr:latest
    container_name: tdarr
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
      - serverIP=0.0.0.0
      - serverPort=8266
      - webUIPort=8265
    volumes:
      - $STACK_DIR/config/tdarr/server:/app/server
      - $STACK_DIR/config/tdarr/configs:/app/configs
      - $STACK_DIR/config/tdarr/logs:/app/logs
      - \${MEDIA_PATH}:/media
    ports:
      - "8265:8265"
      - "8266:8266"
    restart: unless-stopped
    networks:
      - media-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8265"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register service in dashboard
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"

register_service \
"Tdarr" \
"http://localhost:8265" \
"Media" \
"tdarr.png"

}
