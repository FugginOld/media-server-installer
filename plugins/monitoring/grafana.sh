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

PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Monitoring Dashboard"
PLUGIN_CATEGORY="monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORTS=(3000)

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Grafana"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/grafana"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/grafana:/var/lib/grafana
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT/login || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Service
########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "Grafana" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "grafana.png"

    fi

    log "Grafana installation complete"
}