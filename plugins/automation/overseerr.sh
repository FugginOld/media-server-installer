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

PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Media Request Management"
PLUGIN_CATEGORY="automation"

PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORTS=(5055)

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Overseerr"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/overseerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  overseerr:
    image: sctx/overseerr:latest
    container_name: overseerr
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - LOG_LEVEL=info
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/overseerr:/app/config
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
            "Overseerr" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "overseerr.png"

    fi

    log "Overseerr installation complete"
}