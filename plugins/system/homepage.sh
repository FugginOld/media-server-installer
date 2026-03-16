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

PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Media Stack Dashboard"
PLUGIN_CATEGORY="system"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(3001)

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Homepage Dashboard"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}"
    PORT=$(get_port "$PLUGIN_NAME")

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
EOF

# Only mount Docker socket if explicitly authorized
if [[ "${ALLOW_DOCKER_SOCKET:-false}" == "true" ]]; then
    cat <<EOF >> "$TMP_COMPOSE"
      - /var/run/docker.sock:/var/run/docker.sock:ro
EOF
else
    warn "Docker socket access disabled for homepage (security)"
    warn "To enable: export ALLOW_DOCKER_SOCKET=true"
fi

cat <<EOF >> "$TMP_COMPOSE"
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

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then
        register_service \
            "Homepage" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "homepage.png"
    fi

    log "Homepage dashboard installed"
}