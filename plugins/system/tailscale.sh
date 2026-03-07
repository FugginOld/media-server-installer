#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tailscale"
PLUGIN_DESCRIPTION="Mesh VPN for secure remote access"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=()
PLUGIN_HOST_NETWORK=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Tailscale..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/tailscale"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - TZ=\${TIMEZONE}
      - TS_STATE_DIR=/var/lib/tailscale
    volumes:
      - $CONFIG_DIR/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
EOF

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped

EOF

}