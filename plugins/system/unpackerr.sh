#!/usr/bin/env bash

########################################
# Unpackerr Plugin
#
# Automatically extracts downloads from
# SABnzbd so Radarr and Sonarr can import
# completed media files immediately.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Download Extraction Automation"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=(sabnzbd)

PLUGIN_PORTS=()

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

########################################
# Core paths
########################################

STACK_DIR="/opt/media-stack"

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/unpackerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  unpackerr:
    image: golift/unpackerr
    container_name: unpackerr
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/unpackerr:/config
      - $DOWNLOADS_PATH:/downloads
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "pgrep unpackerr || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
EOF

}