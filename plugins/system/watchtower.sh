#!/usr/bin/env bash

########################################
# Watchtower Plugin
#
# Automatically updates Docker containers
# in the Media Stack.
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

echo "Installing Watchtower..."

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    command: --cleanup --schedule "0 0 4 * * *"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TZ=\${TIMEZONE}
    restart: unless-stopped
EOF

echo "Watchtower installation complete."

}