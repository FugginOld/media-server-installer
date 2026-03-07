#!/usr/bin/env bash

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="tautulli"
PLUGIN_DESCRIPTION="Plex monitoring and analytics platform"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("plex")

PLUGIN_DASHBOARD=true
PLUGIN_PORTS=(8181)
PLUGIN_HOST_NETWORK=false

########################################
# Install Service
########################################

install_service() {

echo "Installing Tautulli..."

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

########################################
# Load helpers
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-helper.sh"

########################################
# Create config directory
########################################

mkdir -p "$CONFIG_DIR/tautulli"

########################################
# Reserve port
########################################

PORT_MAPPING=$(get_port_mapping "tautulli" 8181 8181)

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$COMPOSE_FILE"

  tautulli:
    image: lscr.io/linuxserver/tautulli
    container_name: tautulli
    networks:
      - media-network
    ports:
      - "$PORT_MAPPING"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TIMEZONE}
    volumes:
      - $CONFIG_DIR/tautulli:/config
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
      test: ["CMD", "curl", "-f", "http://localhost:8181"]
      interval: 30s
      timeout: 10s
      retries: 3

EOF

########################################
# Register dashboard
########################################

register_service \
"Tautulli" \
"http://localhost:8181" \
"Monitoring" \
"tautulli.png"

}