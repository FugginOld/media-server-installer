#!/usr/bin/env bash

########################################
# Homepage Dashboard Plugin
#
# Provides a unified dashboard for all
# services in the Media Stack.
#
# Displays services registered in the
# service registry.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Service Dashboard"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(3001)

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

PORT=$(get_port_mapping "homepage" 3001 3000)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/homepage"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  homepage:
    image: ghcr.io/gethomepage/homepage
    container_name: homepage
    ports:
      - "$PORT"
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/homepage:/app/config
      - $STACK_DIR/services.json:/app/config/services.json
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3001 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register dashboard service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Homepage" \
"http://localhost:3001" \
"System" \
"homepage.png"

fi

}