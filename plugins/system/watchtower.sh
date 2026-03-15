#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime and libraries
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/lib/runtime.sh"
source "$LIB_DIR/ports.sh"
source "$LIB_DIR/services.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="watchtower"
PLUGIN_DESCRIPTION="Automatic Container Updates"
PLUGIN_CATEGORY="system"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=()

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

    log "Installing Watchtower"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

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

    log "Watchtower installation complete"
}