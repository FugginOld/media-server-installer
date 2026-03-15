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

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex Metrics Exporter"
PLUGIN_CATEGORY="monitoring"

PLUGIN_DEPENDS=(prometheus plex)

PLUGIN_PORTS=(9594)

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

    log "Installing Plex Exporter"

########################################
# Prevent duplicate installs
########################################

    if grep -q "^\s*$PLUGIN_NAME:" "$TMP_COMPOSE" 2>/dev/null; then
        log "$PLUGIN_NAME already installed. Skipping."
        return
    fi

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/$PLUGIN_NAME"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  $PLUGIN_NAME:
    image: ghcr.io/jsclayton/prometheus-plex-exporter
    container_name: plex-exporter
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - TZ=\${TIMEZONE}
      - PLEX_SERVER=http://plex:32400
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT/metrics || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    log "Plex Exporter installation complete"
}