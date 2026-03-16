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

PLUGIN_NAME="example"
PLUGIN_DESCRIPTION="Example Service"
PLUGIN_CATEGORY="system"

PLUGIN_DEPENDS=()

PLUGIN_PORT=8080

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

    log "Installing $PLUGIN_DESCRIPTION"

    ########################################
    # Register port
    ########################################

    local PORT="$PLUGIN_PORT"

    if [[ "$PLUGIN_HOST_NETWORK" != "true" && -n "$PLUGIN_PORT" ]]; then
        register_port "$PLUGIN_NAME" "$PORT"
    fi

    ########################################
    # Create configuration directory
    ########################################

    mkdir -p "$CONFIG_DIR/$PLUGIN_NAME"

    ########################################
    # Add container to docker-compose
    ########################################

cat <<EOF >> "$TMP_COMPOSE"

  $PLUGIN_NAME:
    image: example/image:latest
    container_name: $PLUGIN_NAME
EOF

    ########################################
    # Networking configuration
    ########################################

    if [[ "$PLUGIN_HOST_NETWORK" == "true" ]]; then

cat <<EOF >> "$TMP_COMPOSE"
    network_mode: host
EOF

    else

cat <<EOF >> "$TMP_COMPOSE"
    ports:
      - "$PORT:$PLUGIN_PORT"
EOF

    fi

    ########################################
    # Environment configuration
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
EOF

    ########################################
    # Volumes
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    volumes:
      - ./config/$PLUGIN_NAME:/config
EOF

    ########################################
    # Restart policy
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    restart: unless-stopped
EOF

    ########################################
    # Optional GPU support
    ########################################

    if [[ "${GPU_TYPE:-none}" != "none" ]]; then
        echo "$GPU_DEVICES" >> "$TMP_COMPOSE"
    fi

    ########################################
    # Optional healthcheck
    ########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PLUGIN_PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    ########################################
    # Dashboard registration
    ########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "$PLUGIN_DESCRIPTION" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "$PLUGIN_NAME.png"

    fi

    log "$PLUGIN_DESCRIPTION installation complete"
}