#!/usr/bin/env bash

########################################
# Tautulli Plugin
#
# Provides advanced Plex analytics and
# monitoring including:
# - user playback history
# - bandwidth usage
# - active streams
########################################

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tautulli"
PLUGIN_DESCRIPTION="Plex Analytics Platform"
PLUGIN_CATEGORY="Monitoring"

PLUGIN_DEPENDS=(plex)

PLUGIN_PORTS=(8181)

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

PORT=$(get_port_mapping "tautulli" 8181 8181)

########################################
# Create configuration directory
########################################

mkdir -p "$STACK_DIR/config/tautulli"

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"

  tautulli:
    image: lscr.io/linuxserver/tautulli
    container_name: tautulli
    ports:
      - "$PORT"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - ./config/tautulli:/config
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$STACK_DIR/docker-compose.yml"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8181 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

if [ "$PLUGIN_DASHBOARD" = true ]; then

register_service \
"Tautulli" \
"http://localhost:8181" \
"Monitoring" \
"tautulli.png"

fi

}