#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Prometheus exporter for Plex metrics"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("plex" "prometheus")

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=(9594)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Plex Exporter..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "plex-exporter" 9594 9594)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  plex-exporter:
    image: granra/plex_exporter
    container_name: plex-exporter
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PLEX_ADDR=http://plex:32400
      - TZ=\${TIMEZONE}
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
      test: ["CMD", "wget", "-qO-", "http://localhost:9594/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

}