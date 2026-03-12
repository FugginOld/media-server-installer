#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

set -euo pipefail

########################################
# Load media-stack runtime environment
########################################


########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex Metrics Exporter"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus plex)

PLUGIN_PORTS=(9594)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false


########################################
# Install Service
########################################

install_service() {

echo "Installing Plex Exporter..."

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

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/$PLUGIN_NAME"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  $PLUGIN_NAME:
    image: ghcr.io/jsclayton/prometheus-plex-exporter
    container_name: plex-exporter
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - TZ=\${TIMEZONE}
      - PLEX_SERVER=http://plex:32400
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:${PLUGIN_PORTS[0]}/metrics || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

echo "Plex Exporter installation complete."

}
