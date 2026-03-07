#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Self-hosted services dashboard"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(3001)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Homepage dashboard..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/homepage"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "homepage" 3001 3000)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/homepage:/app/config
      - $STACK_DIR/services.json:/app/config/services.json
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
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Homepage" \
"http://localhost:3001" \
"System" \
"homepage.png"

}