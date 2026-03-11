#!/usr/bin/env bash

########################################
# Plex Exporter Plugin
#
# Exposes Plex metrics for Prometheus.
#
# NOTE:
# Plex token is optional. Metrics that
# require authentication will not be
# available until a token is added
# to stack.env.
########################################

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex Metrics Exporter"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus plex)

PLUGIN_PORTS=(9594)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Plex Exporter..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  plex-exporter:
    image: ghcr.io/jsclayton/prometheus-plex-exporter
    container_name: plex-exporter
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    environment:
      - TZ=\${TIMEZONE}
      - PLEX_SERVER=http://plex:32400
      - PLEX_TOKEN=\${PLEX_TOKEN}
    restart: unless-stopped

EOF

########################################
# User notice
########################################

echo "Plex Exporter installed."
echo "Optional: add PLEX_TOKEN to stack.env for authenticated metrics."

}
