#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Load environment
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

PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle Management"
PLUGIN_CATEGORY="Automation"

PLUGIN_DEPENDS=(radarr sonarr)

PLUGIN_PORTS=(6767)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Bazarr..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/bazarr"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/bazarr:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
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
"Bazarr" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"bazarr.png"

fi

echo "Bazarr installation complete."

}
