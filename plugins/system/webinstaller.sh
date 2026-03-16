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

PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Web Landing Page"
PLUGIN_CATEGORY="system"

PLUGIN_DEPENDS=()

PLUGIN_PORT=8088

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Web Installer"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/webinstaller"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  webinstaller:
    image: nginx:alpine
    container_name: webinstaller
    ports:
      - "$PORT:$PLUGIN_PORT"
    volumes:
      - ./config/webinstaller:/usr/share/nginx/html
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
# Register service
########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "Web Installer" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "webinstaller.png"

    fi

    log "Web Installer installation complete"
}