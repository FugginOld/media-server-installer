#!/usr/bin/env bash

########################################
# Web Installer Plugin
#
# Provides a simple web landing page
# for accessing Media Stack services
# and documentation.
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Web Landing Page"
PLUGIN_CATEGORY="System"

PLUGIN_DEPENDS=()

PLUGIN_PORTS=(8088)

PLUGIN_HOST_NETWORK=false

PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

########################################
# Core paths
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/port-helper.sh"
source "$INSTALL_DIR/scripts/service-registry.sh"

########################################
# Request port mapping
########################################

PORT=$(get_port_mapping "webinstaller" 8088 80)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/webinstaller"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  webinstaller:
    image: nginx:alpine
    container_name: webinstaller
    ports:
      - "$PORT"
    volumes:
      - ./config/webinstaller:/usr/share/nginx/html
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8088 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Web Installer" \
"http://localhost:8088" \
"System" \
"webinstaller.png"

fi

}