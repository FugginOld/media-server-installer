#!/usr/bin/env bash

########################################
# Tdarr Plugin
#
# Provides automated transcoding and
# media optimization for the Media Stack.
#
# Integrates with Plex media libraries
# and supports GPU acceleration.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tdarr"
PLUGIN_DESCRIPTION="Distributed Transcoding System"
PLUGIN_CATEGORY="Media"

PLUGIN_DEPENDS=(plex)

PLUGIN_PORTS=(8265)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

########################################
# Core paths
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "tdarr" 8265 8265)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/tdarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  tdarr:
    image: ghcr.io/haveagitgat/tdarr
    container_name: tdarr
    ports:
      - "$PORT"
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/tdarr:/app/config
      - $MEDIA_PATH:/media
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    restart: unless-stopped
EOF

########################################
# GPU Support
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8265 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Tdarr" \
"http://localhost:8265" \
"Media" \
"tdarr.png"

fi

}