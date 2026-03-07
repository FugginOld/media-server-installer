#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="glances"
PLUGIN_DESCRIPTION="Real-time system monitoring dashboard"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(61208)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Glances..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "glances" 61208 61208)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - TZ=\${TIMEZONE}
      - GLANCES_OPT=-w
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
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
      test: ["CMD", "wget", "-qO-", "http://localhost:61208"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Glances" \
"http://localhost:61208" \
"Monitoring" \
"glances.png"

}