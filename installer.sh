#!/usr/bin/env bash

set -e

########################################
# Variables
########################################

STACK_DIR="/opt/media-stack"
PLUGIN_DIR="./plugins"

SELECTED_SERVICES=()

########################################
# Load core modules
########################################

source ./core/platform.sh
source ./core/directories.sh
source ./core/hardware.sh
source ./core/docker.sh
source ./core/config-wizard.sh

########################################
# Ensure stack directory exists
########################################

mkdir -p "$STACK_DIR"

########################################
# Run configuration wizard
########################################

run_configuration_wizard

########################################
# Load saved configuration
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Detect platform
########################################

detect_platform

########################################
# Detect hardware
########################################

detect_hardware

########################################
# Choose installation mode
########################################

MODE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation mode" \
15 60 2 \
quick "Recommended full media stack" \
custom "Select services manually" \
3>&1 1>&2 2>&3)

########################################
# Quick install list
########################################

if [ "$MODE" = "quick" ]; then

SELECTED_SERVICES=(
plex
radarr
sonarr
prowlarr
bazarr
sabnzbd
unpackerr
homepage
watchtower
tailscale
prometheus
nodeexporter
grafana
tautulli
plex-exporter
)

else

########################################
# Discover plugins
########################################

discover_plugins

########################################
# Prompt user selection
########################################

select_services

fi

########################################
# Resolve dependencies
########################################

resolve_dependencies

########################################
# Initialize docker compose file
########################################

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

cat <<EOF > "$COMPOSE_FILE"
version: "3.9"

networks:
  media-network:

services:

EOF

########################################
# Install plugins
########################################

echo ""
echo "Installing services..."
echo ""

for SERVICE in "${SELECTED_SERVICES[@]}"
do

echo "Installing $SERVICE"

install_plugin "$SERVICE"

done

########################################
# Ensure compose helper executable
########################################

chmod +x ./scripts/compose.sh

########################################
# Start stack using compose helper
########################################

echo ""
echo "Starting containers..."
echo ""

bash ./scripts/compose.sh up

########################################
# Post-install automation
########################################

if [ -f ./scripts/post-install.sh ]; then
bash ./scripts/post-install.sh
fi

########################################
# Display dashboard information
########################################

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================"
echo " Installation Complete"
echo "========================================"
echo ""

echo "Dashboard:"
echo "http://$SERVER_IP:3000"
echo ""

echo "Service list:"
echo ""

if [ -f "$STACK_DIR/services.json" ]; then

cat "$STACK_DIR/services.json" \
| jq -r '.services[] | "\(.name) -> \(.url)"'

fi

echo ""
echo "Manage your stack using:"
echo ""
echo "media-stack status"
echo "media-stack services"
echo "media-stack update"
echo ""

echo "Enjoy your media stack!"
echo ""