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

PLUGIN_NAME="nodeexporter"
PLUGIN_DESCRIPTION="System Metrics Exporter"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORTS=(9100)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Node Exporter..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  nodeexporter:
    image: prom/node-exporter:latest
    container_name: nodeexporter
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
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

echo "Node Exporter installation complete."

}
