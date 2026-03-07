#!/usr/bin/env bash

########################################
# Plex Plugin
#
# Provides the main media streaming
# server for the Media Stack.
#
# Supports hardware transcoding using
# Intel, AMD, or NVIDIA GPUs.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="plex"
PLUGIN_DESCRIPTION="Media Streaming Server"
PLUGIN_CATEGORY="Media"

PLUGIN_DEPENDS=()

# Plex default web port
PLUGIN_PORTS=(32400)

# Plex works best with host networking
PLUGIN_HOST_NETWORK=true

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

source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/plex"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  plex:
    image: lscr.io/linuxserver/plex
    container_name: plex
    network_mode: host
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
      - VERSION=docker
    volumes:
      - ./config/plex:/config
      - $MEDIA_PATH:/media
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    restart: unless-stopped
EOF

########################################
# GPU support (Intel / AMD / NVIDIA)
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:32400/web || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Plex" \
"http://localhost:32400/web" \
"Media" \
"plex.png"

fi

}