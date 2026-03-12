#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

set -euo pipefail

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
# Load media-stack runtime environment
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

# Whether the service should appear in dashboards
PLUGIN_DASHBOARD=true


########################################
# Install Service
########################################

install_service() {

echo "Installing $PLUGIN_NAME..."

########################################
# Prevent duplicate installs
########################################

if grep -q "^\s*$PLUGIN_NAME:" "$TMP_COMPOSE" 2>/dev/null; then
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

cat <<EOF >> "$TMP_COMPOSE"

  $PLUGIN_NAME:
    image: $PLUGIN_IMAGE
    container_name: $PLUGIN_NAME
EOF


########################################
# Networking configuration
########################################

if [ "$PLUGIN_HOST_NETWORK" = true ]; then

cat <<EOF >> "$TMP_COMPOSE"
    network_mode: host
EOF

else

cat <<EOF >> "$TMP_COMPOSE"
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
EOF

fi


########################################
# Container configuration
########################################

cat <<EOF >> "$TMP_COMPOSE"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/$PLUGIN_NAME:/config
    restart: unless-stopped
EOF


########################################
# Register service in dashboard
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
