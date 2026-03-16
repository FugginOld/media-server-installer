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

PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle Management"
PLUGIN_CATEGORY="automation"

PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORT=6767

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Bazarr"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/bazarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    ports:
      - "$PORT:$PLUGIN_PORT"
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
            "Bazarr" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "bazarr.png"

    fi

    log "Bazarr installation complete"
}