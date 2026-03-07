#!/usr/bin/env bash

########################################
# Watchtower Plugin
#
# Automatically updates Docker containers
# in the Media Stack.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="watchtower"
PLUGIN_DESCRIPTION="Automatic Container Updates"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=()

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

########################################
# Core paths
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --schedule "0 0 4 * * *"
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "pgrep watchtower || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
EOF

}