#!/usr/bin/env bash

########################################
# Media Stack Plugin Template
#
# This template defines the standard
# structure for all Media Stack plugins.
#
# Plugins should follow this structure
# so they integrate properly with:
#
# - Port registry
# - Service registry
# - Directory structure
# - GPU support
# - Health monitoring
# - Dashboard systems
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="example"
PLUGIN_DESCRIPTION="Example Service"
PLUGIN_CATEGORY="Utility"

# Dependencies on other plugins
PLUGIN_DEPENDS=()

# Default ports used by this service
PLUGIN_PORTS=(1234)

# Whether service requires host networking
PLUGIN_HOST_NETWORK=false

# Whether service appears in dashboard
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

PORT=$(get_port_mapping "$PLUGIN_NAME" 1234 1234)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/$PLUGIN_NAME"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  $PLUGIN_NAME:
    image: example/example:latest
    container_name: $PLUGIN_NAME
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/$PLUGIN_NAME:/config
    restart: unless-stopped
EOF

########################################
# GPU support (if available)
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi

########################################
# Health check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:1234 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service for dashboards
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"$PLUGIN_NAME" \
"http://localhost:1234" \
"$PLUGIN_CATEGORY" \
"$PLUGIN_NAME.png"

fi

}