#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Load installer libraries
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
#Plugin Metadata
########################################

PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Automatic Archive Extraction"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=(sabnzbd)

PLUGIN_PORTS=()

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Unpackerr..."

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/unpackerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  unpackerr:
    image: ghcr.io/unpackerr/unpackerr:latest
    container_name: unpackerr
    environment:
      - TZ=\${TIMEZONE}
      - UNPACKERR_DEBUG=false
    volumes:
      - ./config/unpackerr:/config
      - $DOWNLOADS_PATH:/downloads
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "pgrep unpackerr || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
EOF

echo "Unpackerr installation complete."

}
