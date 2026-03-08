#!/usr/bin/env bash

########################################
# Tailscale Plugin
#
# Provides secure remote access to the
# Media Stack using a mesh VPN network.
########################################

########################################
# Load Media Stack Environment
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

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

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

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "tailscale status || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
EOF

echo "Tailscale installation complete."

}