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

PLUGIN_NAME="plex"
PLUGIN_DESCRIPTION="Plex Media Server"
PLUGIN_CATEGORY="media"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(32400)

PLUGIN_HOST_NETWORK=true
PLUGIN_DASHBOARD=true

########################################
# Plugin install
########################################

install_service() {

    log "Installing Plex Media Server"

    ########################################
    # Register port if needed
    ########################################

    local PORT="${PLUGIN_PORTS[0]}"

    if [[ "$PLUGIN_HOST_NETWORK" != "true" ]]; then
        register_port "$PLUGIN_NAME" "$PORT"
    fi

    ########################################
    # Create configuration directory
    ########################################

    mkdir -p "$CONFIG_DIR/plex"

    ########################################
    # Add container to docker-compose
    ########################################

cat <<EOF >> "$TMP_COMPOSE"

  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
EOF

    ########################################
    # Networking
    ########################################

    if [[ "$PLUGIN_HOST_NETWORK" == "true" ]]; then

cat <<EOF >> "$TMP_COMPOSE"
    network_mode: host
EOF

    else

cat <<EOF >> "$TMP_COMPOSE"
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
EOF

    fi

    ########################################
    # Container configuration
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
      - VERSION=docker
    volumes:
      - ./config/plex:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
      - $MEDIA_PATH:/media
    restart: unless-stopped
EOF

    ########################################
    # GPU support
    ########################################

    if [[ "${GPU_TYPE:-none}" != "none" ]]; then
        echo "$GPU_DEVICES" >> "$TMP_COMPOSE"
    fi

    ########################################
    # Healthcheck
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:32400/web || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    ########################################
    # Dashboard registration
    ########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then
        register_service \
            "Plex" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "plex.png" \
            "/web"
    fi

    log "Plex installation complete"
}