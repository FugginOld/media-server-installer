#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Metrics dashboard and visualization"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("prometheus")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(3000)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Grafana..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/grafana"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "grafana" 3000 3000)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  grafana:
    image: grafana/grafana
    container_name: grafana
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/grafana:/var/lib/grafana
EOF

########################################
# GPU Support
########################################

if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$COMPOSE_FILE"
fi

########################################
# Restart policy
########################################

cat <<EOF >> "$COMPOSE_FILE"
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$COMPOSE_FILE"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Grafana" \
"http://localhost:3000" \
"Monitoring" \
"grafana.png"

}