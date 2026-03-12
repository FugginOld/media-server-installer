#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Load environment
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

PLUGIN_NAME="prometheus"
PLUGIN_DESCRIPTION="Metrics Collection Server"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(9090)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

echo "Installing Prometheus..."

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "$PLUGIN_NAME" "${PLUGIN_PORTS[0]}")

########################################
# Create configuration directory
########################################

mkdir -p "$CONFIG_DIR/prometheus"

########################################
# Generate default Prometheus config
########################################

cat <<EOF > "$CONFIG_DIR/prometheus/prometheus.yml"
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']

  - job_name: 'plex'
    static_configs:
      - targets: ['plex-exporter:9594']

  - job_name: 'glances'
    static_configs:
      - targets: ['glances:61208']
EOF

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "$PORT:${PLUGIN_PORTS[0]}"
    volumes:
      - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PORT/-/healthy || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register Service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Prometheus" \
"http://localhost:$PORT" \
"$PLUGIN_CATEGORY" \
"prometheus.png"

fi

echo "Prometheus installation complete."

}
