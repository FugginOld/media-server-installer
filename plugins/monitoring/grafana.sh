#!/usr/bin/env bash

########################################
# Grafana Plugin
#
# Provides visualization dashboards for
# Prometheus monitoring data.
#
# Displays:
# - system metrics
# - Plex streaming metrics
# - network statistics
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Monitoring Dashboard"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORTS=(3000)

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

PORT=$(get_port_mapping "grafana" 3000 3000)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/grafana"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "$PORT"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/grafana:/var/lib/grafana
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Grafana" \
"http://localhost:3000" \
"Monitoring" \
"grafana.png"

fi

}