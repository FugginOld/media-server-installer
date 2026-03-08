#!/usr/bin/env bash

########################################
# Plex Exporter Plugin
#
# Exposes Plex metrics for Prometheus.
#
# Metrics include:
# - active streams
# - bandwidth usage
# - transcoding activity
########################################

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex Metrics Exporter"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus plex)

PLUGIN_PORTS=(9594)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Plex Exporter..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  plex-exporter:
    image: ghcr.io/ekofr/plex-exporter:latest
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

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT/metrics || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

echo "Plex Exporter installation complete."

}