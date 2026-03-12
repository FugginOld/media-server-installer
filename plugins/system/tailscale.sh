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

source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tailscale"
PLUGIN_DESCRIPTION="Secure Remote Access VPN"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=()

PLUGIN_HOST_NETWORK=true

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Tailscale..."

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/tailscale"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "tailscale status || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
EOF

echo "Tailscale installation complete."

}
