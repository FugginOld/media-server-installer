#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="example"
PLUGIN_DESCRIPTION="Example Service"
PLUGIN_CATEGORY="Utility"
PLUGIN_DEPENDS=()
PLUGIN_PORTS=(1234)
PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Assign port
########################################

PORT_MAPPING=$(get_port_mapping "$PLUGIN_NAME" 1234 1234)

########################################
# Create config directory
########################################

mkdir -p "$STACK_DIR/config/$PLUGIN_NAME"

########################################
# Add container to compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  $PLUGIN_NAME:
    image: example/example:latest
    container_name: $PLUGIN_NAME
    ports:
      - "$PORT_MAPPING"
    volumes:
      - ./config/$PLUGIN_NAME:/config
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    restart: unless-stopped
EOF

########################################
# GPU Support
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:1234 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Dashboard
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"$PLUGIN_NAME" \
"http://localhost:1234" \
"$PLUGIN_CATEGORY" \
"$PLUGIN_NAME.png"

fi

}