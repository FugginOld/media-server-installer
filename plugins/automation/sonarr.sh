#!/usr/bin/env bash

########################################
# Sonarr Plugin
#
# Manages TV series downloads for the
# Media Stack automation ecosystem.
#
# Integrates with:
# - SABnzbd
# - Prowlarr
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="sonarr"
PLUGIN_DESCRIPTION="TV Automation Manager"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=(sabnzbd)

PLUGIN_PORTS=(8989)

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

PORT=$(get_port_mapping "sonarr" 8989 8989)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/sonarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  sonarr:
    image: lscr.io/linuxserver/sonarr
    container_name: sonarr
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/sonarr:/config
      - $TV_PATH:/tv
      - $DOWNLOADS_PATH:/downloads
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8989 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Sonarr" \
"http://localhost:8989" \
"Automation" \
"sonarr.png"

fi

}