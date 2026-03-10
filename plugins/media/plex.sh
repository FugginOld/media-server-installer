#!/usr/bin/env bash

########################################
# Plex Plugin
#
# Provides the main media streaming
# server for the Media Stack.
#
# Supports hardware transcoding using
# Intel, AMD, or NVIDIA GPUs.
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

PLUGIN_NAME="plex"
PLUGIN_DESCRIPTION="Plex Media Server"
PLUGIN_CATEGORY="Media"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(32400)

PLUGIN_HOST_NETWORK=true

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Plex Media Server..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/plex"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
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
      - VERSION=docker
    volumes:
      - ./config/plex:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
      - $MEDIA_PATH:/media
    restart: unless-stopped
EOF

########################################
# GPU support (if available)
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$TMP_COMPOSE"
fi

########################################
# Health check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:32400/web || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Plex" \
"http://localhost:32400/web" \
"$PLUGIN_CATEGORY" \
"plex.png"

fi

echo "Plex installation complete."

}