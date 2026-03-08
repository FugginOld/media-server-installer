#!/usr/bin/env bash

########################################
# Overseerr Plugin
#
# Provides a request management system
# for Plex users to request movies and
# TV shows.
#
# Integrates with:
# - Radarr
# - Sonarr
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

PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Media Request Management"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORTS=(5055)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Overseerr..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/overseerr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  overseerr:
    image: sctx/overseerr:latest
    container_name: overseerr
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - LOG_LEVEL=info
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/overseerr:/app/config
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Overseerr" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"overseerr.png"

fi

echo "Overseerr installation complete."

}