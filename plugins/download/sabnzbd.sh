#!/usr/bin/env bash

########################################
# SABnzbd Plugin
#
# Provides Usenet downloading for the
# Media Stack automation ecosystem.
#
# Used by:
# - Radarr
# - Sonarr
# - Bazarr
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="sabnzbd"
PLUGIN_DESCRIPTION="Usenet Downloader"
PLUGIN_CATEGORY="Download"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(8080)

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

PORT=$(get_port_mapping "sabnzbd" 8080 8080)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/sabnzbd"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd
    container_name: sabnzbd
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/sabnzbd:/config
      - $DOWNLOADS_PATH:/downloads
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"SABnzbd" \
"http://localhost:8080" \
"Download" \
"sabnzbd.png"

fi

}