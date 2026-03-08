#!/usr/bin/env bash

########################################
# Media Stack Plugin Template
#
# This file defines the standard format
# for Media Stack plugins.
#
# Plugins are responsible for installing
# individual services and integrating
# them into the Media Stack ecosystem.
#
# Every plugin must:
#
# 1. Define plugin metadata
# 2. Request ports through the port helper
# 3. Create required configuration folders
# 4. Append its container definition to
#    the docker-compose.yml
# 5. Optionally register itself in the
#    service registry for dashboards
#
# Plugins integrate with the following
# core systems:
#
# - Environment loader (env.sh)
# - Port registry
# - Service registry
# - Docker compose generator
# - GPU detection
# - Dashboard systems
#
# Plugin lifecycle during installation:
#
# installer.sh
#   ├─ loads plugin
#   ├─ resolves dependencies
#   └─ runs install_service()
#
# install_service() should:
#
# 1. Request required ports
# 2. Create config directories
# 3. Append docker-compose service block
# 4. Register dashboard entry
#
# Important:
#
# Plugins must be idempotent.
# Running the installer multiple times
# must not create duplicate services.
#
########################################


########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"


########################################
# Load Helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"


########################################
# Plugin Metadata
########################################

# Unique plugin identifier
PLUGIN_NAME="example"

# Human readable description
PLUGIN_DESCRIPTION="Example Service"

# Category used by dashboards
PLUGIN_CATEGORY="Utility"

# Plugin version
PLUGIN_VERSION="1.0"

# Container image
PLUGIN_IMAGE="example/example:latest"

# Dependencies on other plugins
PLUGIN_DEPENDS=()

# Default ports used by the service
PLUGIN_PORTS=(1234)

# Whether the container requires host networking
PLUGIN_HOST_NETWORK=false

# Whether the service should appear
# in dashboard systems
PLUGIN_DASHBOARD=true


########################################
# Install Service
########################################

install_service() {

echo "Installing $PLUGIN_NAME..."

########################################
# Prevent duplicate installs
########################################

if grep -q "container_name: $PLUGIN_NAME" "$STACK_DIR/docker-compose.yml" 2>/dev/null; then
echo "$PLUGIN_NAME already installed. Skipping."
return
fi


########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

if [ -z "$PORT" ]; then
echo "Failed to allocate port for $PLUGIN_NAME"
exit 1
fi


########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/$PLUGIN_NAME"


########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  $PLUGIN_NAME:
    image: $PLUGIN_IMAGE
    container_name: $PLUGIN_NAME
EOF


########################################
# Networking configuration
########################################

if [ "$PLUGIN_HOST_NETWORK" = true ]; then

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    network_mode: host
EOF

else

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    networks:
      - media-network
EOF

fi


########################################
# Environment variables
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
EOF


########################################
# Volumes
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    volumes:
      - ./config/$PLUGIN_NAME:/config
EOF


########################################
# GPU Support (if detected)
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi


########################################
# Health check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:$PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF


########################################
# Restart policy
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    restart: unless-stopped
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