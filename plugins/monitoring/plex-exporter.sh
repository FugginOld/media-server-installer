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
# Plugin Metadata
########################################

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex Metrics Exporter"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(plex prometheus)

PLUGIN_PORTS=(9594)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

########################################
# Core paths
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "plex-exporter" 9594 9594)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  plex-exporter:
    image: ghcr.io/timothymiller/plex-exporter
    container_name: plex-exporter
    ports:
      - "$PORT"
    environment:
      - PLEX_ADDR=http://plex:32400
      - PLEX_TOKEN=\${PLEX_TOKEN}
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9594/metrics || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

}