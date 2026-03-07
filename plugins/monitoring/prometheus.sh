#!/usr/bin/env bash

########################################
# Prometheus Plugin
#
# Provides the metrics collection
# system for the Media Stack.
#
# Prometheus collects metrics from:
# - Node Exporter
# - Plex Exporter
# - Glances
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="prometheus"
PLUGIN_DESCRIPTION="Metrics Monitoring System"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(9090)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

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
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "prometheus" 9090 9090)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/prometheus"

########################################
# Create default Prometheus config
########################################

cat <<EOF > "$STACK_DIR/config/prometheus/prometheus.yml"
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']

  - job_name: 'plex'
    static_configs:
      - targets: ['plex-exporter:9594']

  - job_name: 'glances'
    static_configs:
      - targets: ['glances:61208']
EOF

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "$PORT"
    volumes:
      - ./config/prometheus:/etc/prometheus
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9090 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Prometheus" \
"http://localhost:9090" \
"Monitoring" \
"prometheus.png"

fi

}