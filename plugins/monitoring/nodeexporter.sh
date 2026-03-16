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

PLUGIN_NAME="nodeexporter"
PLUGIN_DESCRIPTION="System Metrics Exporter"
PLUGIN_CATEGORY="monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORT=9100

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

    log "Installing Node Exporter"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  nodeexporter:
    image: prom/node-exporter:latest
    container_name: nodeexporter
    ports:
      - "$PORT:$PLUGIN_PORT"
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

    log "Node Exporter installation complete"
}