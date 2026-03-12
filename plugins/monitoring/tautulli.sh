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
# Load Environment
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

PLUGIN_NAME="tautulli"
PLUGIN_DESCRIPTION="Plex Analytics and Monitoring"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(plex)

PLUGIN_PORTS=(8181)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Tautulli..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/tautulli"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  tautulli:
    image: lscr.io/linuxserver/tautulli:latest
    container_name: tautulli
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/tautulli:/config
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
"Tautulli" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"tautulli.png"

fi

echo "Tautulli installation complete."

}
