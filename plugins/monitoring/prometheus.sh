#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="prometheus"
PLUGIN_DESCRIPTION="Metrics collection system"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=(9090)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Prometheus..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/prometheus"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "prometheus" 9090 9090)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    volumes:
      - $CONFIG_DIR/prometheus:/etc/prometheus
EOF

########################################
# GPU Support
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$COMPOSE_FILE"
fi

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
      test: ["CMD", "wget", "-qO-", "http://localhost:9090"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

}