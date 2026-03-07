#!/usr/bin/env bash

########################################
# Node Exporter Plugin
#
# Provides system metrics for Prometheus.
#
# Metrics include:
# - CPU usage
# - Memory usage
# - Disk I/O
# - Network activity
########################################

########################################
# Plugin Metadata
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

PORT=$(get_port_mapping "nodeexporter" 9100 9100)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    ports:
      - "$PORT"
    pid: host
    volumes:
      - /:/host:ro,rslave
    command:
      - '--path.rootfs=/host'
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9100/metrics || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

}