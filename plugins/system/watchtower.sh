#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="watchtower"
PLUGIN_DESCRIPTION="Automatic Docker container updates"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=false
PLUGIN_PORTS=()
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Watchtower..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    networks:
      - media-network
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --interval 86400
EOF

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped

EOF

}