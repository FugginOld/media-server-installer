#!/usr/bin/env bash

########################################
# Prowlarr Plugin
#
# Manages indexers for the Media Stack
# automation ecosystem.
#
# Integrates with:
# - Radarr
# - Sonarr
# - Bazarr
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="prowlarr"
PLUGIN_DESCRIPTION="Indexer Manager"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(9696)

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

PORT=$(get_port_mapping "prowlarr" 9696 9696)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/prowlarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  prowlarr:
    image: lscr.io/linuxserver/prowlarr
    container_name: prowlarr
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/prowlarr:/config
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9696 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Prowlarr" \
"http://localhost:9696" \
"Automation" \
"prowlarr.png"

fi

}