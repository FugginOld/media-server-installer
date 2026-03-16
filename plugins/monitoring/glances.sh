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

PLUGIN_NAME="glances"
PLUGIN_DESCRIPTION="System Monitoring Dashboard"
PLUGIN_CATEGORY="monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORT=61208

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Glances"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/glances"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  glances:
    image: nicolargo/glances:latest
    container_name: glances
    ports:
      - "$PORT:$PLUGIN_PORT"
    environment:
      - GLANCES_OPT=-w
      - TZ=\${TIMEZONE}
    volumes:
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

########################################
# Register Service
########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "Glances" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "glances.png"

    fi

    log "Glances installation complete"
}