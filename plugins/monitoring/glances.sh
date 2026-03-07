#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="glances"
PLUGIN_DESCRIPTION="System monitoring dashboard"
PLUGIN_CATEGORY="monitoring"
PLUGIN_DEPENDS=()
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

STACK_DIR="/opt/media-stack"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

echo "Installing Glances..."

########################################
# Ensure config directory exists
########################################

mkdir -p "$STACK_DIR/config/glances"

########################################
# Add container to compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    environment:
      - TZ=\${TIMEZONE}
      - GLANCES_OPT=-w
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - $STACK_DIR/config/glances:/config
    ports:
      - "61208:61208"
    restart: unless-stopped
    networks:
      - media-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:61208"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register service in dashboard
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"

register_service \
"Glances" \
"http://localhost:61208" \
"Monitoring" \
"glances.png"

}
