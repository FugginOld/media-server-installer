#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime and libraries
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/lib/runtime.sh"
source "$LIB_DIR/ports.sh"
source "$LIB_DIR/services.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="sabnzbd"
PLUGIN_DESCRIPTION="Usenet Downloader"
PLUGIN_CATEGORY="download"

PLUGIN_DEPENDS=()

PLUGIN_PORT=8080

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing SABnzbd"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/sabnzbd"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    ports:
      - "$PORT:$PLUGIN_PORT"
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

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Service
########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "SABnzbd" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "sabnzbd.png"

    fi

    log "SABnzbd installation complete"
}