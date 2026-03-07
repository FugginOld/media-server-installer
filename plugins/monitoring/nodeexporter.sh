#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="nodeexporter"
PLUGIN_DESCRIPTION="Prometheus host metrics exporter"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("prometheus")

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=(9100)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Node Exporter..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "nodeexporter" 9100 9100)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
EOF

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$COMPOSE_FILE"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:9100/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

}