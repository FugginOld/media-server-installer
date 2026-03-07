#!/usr/bin/env bash

########################################
# Radarr Plugin
#
# Manages movie downloads for the
# Media Stack automation ecosystem.
#
# Integrates with:
# - SABnzbd
# - Prowlarr
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="radarr"
PLUGIN_DESCRIPTION="Movie Automation Manager"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=(sabnzbd)

PLUGIN_PORTS=(7878)

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

PORT=$(get_port_mapping "radarr" 7878 7878)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/radarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  radarr:
    image: lscr.io/linuxserver/radarr
    container_name: radarr
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/radarr:/config
      - $MOVIES_PATH:/movies
      - $DOWNLOADS_PATH:/downloads
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:7878 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Radarr" \
"http://localhost:7878" \
"Automation" \
"radarr.png"

fi

}