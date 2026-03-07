#!/usr/bin/env bash

########################################
# Overseerr Plugin
#
# Provides a request management system
# for Plex users to request movies and
# TV shows.
#
# Integrates with:
# - Radarr
# - Sonarr
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Media Request Manager"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORTS=(5055)

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

PORT=$(get_port_mapping "overseerr" 5055 5055)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/overseerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  overseerr:
    image: lscr.io/linuxserver/overseerr
    container_name: overseerr
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/overseerr:/config
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5055 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Overseerr" \
"http://localhost:5055" \
"Automation" \
"overseerr.png"

fi

}