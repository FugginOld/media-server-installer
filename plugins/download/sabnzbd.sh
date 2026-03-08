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
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

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

echo "Installing SABnzbd..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/sabnzbd"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
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
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"SABnzbd" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"sabnzbd.png"

fi

echo "SABnzbd installation complete."

}