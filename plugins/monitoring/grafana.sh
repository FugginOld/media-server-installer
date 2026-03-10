#!/usr/bin/env bash

########################################
# Grafana Plugin
#
# Provides visualization dashboards for
# Prometheus monitoring data.
#
# Displays:
# - system metrics
# - Plex streaming metrics
# - network statistics
########################################

########################################
# Load Media Stack Environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Monitoring Dashboard"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(prometheus)

PLUGIN_PORTS=(3000)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Grafana..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

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

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Grafana" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"grafana.png"

fi

echo "Grafana installation complete."

}