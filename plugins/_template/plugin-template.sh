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
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

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

echo "Installing $PLUGIN_NAME..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/$PLUGIN_NAME"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  $PLUGIN_NAME:
    image: example/example:latest
    container_name: $PLUGIN_NAME
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
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
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT || exit 1"]
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
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"$PLUGIN_NAME.png"

fi

echo "$PLUGIN_NAME installation complete."

}