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

PLUGIN_NAME="tdarr"
PLUGIN_DESCRIPTION="Media Transcoding Automation"
PLUGIN_CATEGORY="media"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(8265)

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Tdarr"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directories
########################################

    mkdir -p "$CONFIG_DIR/tdarr/server"
    mkdir -p "$CONFIG_DIR/tdarr/config"
    mkdir -p "$CONFIG_DIR/tdarr/logs"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  tdarr:
    image: ghcr.io/haveagitgat/tdarr:latest
    container_name: tdarr
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - TZ=\${TIMEZONE}
      - PUID=\${PUID}
      - PGID=\${PGID}
    volumes:
      - ./config/tdarr/server:/app/server
      - ./config/tdarr/config:/app/configs
      - ./config/tdarr/logs:/app/logs
      - $MEDIA_PATH:/media
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    restart: unless-stopped
EOF

########################################
# GPU Support
########################################

    if [[ "${GPU_TYPE:-none}" != "none" ]]; then
        echo "$GPU_DEVICES" >> "$TMP_COMPOSE"
    fi

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
            "Tdarr" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "tdarr.png"

    fi

    log "Tdarr installation complete"
}