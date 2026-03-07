#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Web-based installer interface"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(8081)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Web Installer..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/webinstaller"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "webinstaller" 8081 8081)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  webinstaller:
    image: nginx:alpine
    container_name: webinstaller
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/webinstaller:/usr/share/nginx/html
EOF

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
      test: ["CMD", "wget", "-qO-", "http://localhost:8081"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Web Installer" \
"http://localhost:8081" \
"System" \
"webinstaller.png"

}