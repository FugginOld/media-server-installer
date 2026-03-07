#!/usr/bin/env bash

########################################
# Glances Plugin
#
# Provides real-time system monitoring
# and exports metrics for Prometheus.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="glances"
PLUGIN_DESCRIPTION="Real-time System Monitoring"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORTS=(61208)

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

PORT=$(get_port_mapping "glances" 61208 61208)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  glances:
    image: nicolargo/glances
    container_name: glances
    ports:
      - "$PORT"
    environment:
      - GLANCES_OPT=-w
    pid: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:61208 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Glances" \
"http://localhost:61208" \
"Monitoring" \
"glances.png"

fi

}