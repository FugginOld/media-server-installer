#!/usr/bin/env bash

########################################
# Bazarr Plugin
#
# Provides automatic subtitle downloads
# for movies and TV series managed by
# Radarr and Sonarr.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle Manager"
PLUGIN_CATEGORY="Automation"

# Bazarr works with Radarr and Sonarr
PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORTS=(6767)

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

PORT=$(get_port_mapping "bazarr" 6767 6767)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/bazarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  bazarr:
    image: lscr.io/linuxserver/bazarr
    container_name: bazarr
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/bazarr:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:6767 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Bazarr" \
"http://localhost:6767" \
"Automation" \
"bazarr.png"

fi

}