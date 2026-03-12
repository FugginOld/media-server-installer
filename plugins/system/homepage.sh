#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Load installer libraries
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
#Plugin Metadata
########################################

PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Media Stack Dashboard"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(3001)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Homepage Dashboard..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/homepage"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - TZ=\${TIMEZONE}
      - HOMEPAGE_ALLOWED_HOSTS=*
    volumes:
      - ./config/homepage:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
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

echo "Homepage dashboard installed."

}
