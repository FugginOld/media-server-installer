#!/usr/bin/env bash

set -e

########################################
# Directories
########################################

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="/opt/media-stack"

########################################
# Preflight
########################################

bash "$INSTALL_DIR/scripts/preflight.sh"

########################################
# Load core modules
########################################

source "$INSTALL_DIR/core/platform.sh"
source "$INSTALL_DIR/core/docker.sh"
source "$INSTALL_DIR/core/hardware.sh"
source "$INSTALL_DIR/core/directories.sh"
source "$INSTALL_DIR/core/config-wizard.sh"

########################################
# Detect platform
########################################

detect_platform

########################################
# Ensure Docker
########################################

ensure_docker

########################################
# Hardware detection
########################################

detect_gpu
configure_gpu_devices
install_nvidia_runtime

########################################
# Directory setup
########################################

setup_directories

########################################
# Configuration wizard
########################################

run_configuration_wizard

########################################
# Load configuration
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Validate plugins
########################################

bash "$INSTALL_DIR/scripts/plugin-validator.sh"

########################################
# Initialize registries
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
source "$INSTALL_DIR/scripts/port-registry.sh"

init_registry
init_port_registry

########################################
# Install mode
########################################

MODE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation mode" \
15 60 2 \
quick "Recommended stack" \
custom "Choose services manually" \
3>&1 1>&2 2>&3)

########################################
# Quick install services
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

discover_plugins
select_services

fi

########################################
# Resolve dependencies
########################################

resolve_dependencies

########################################
# Initialize compose file
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
# Start containers
########################################

bash "$INSTALL_DIR/scripts/compose.sh" up

########################################
# Post install
########################################

if [ -f "$INSTALL_DIR/scripts/post-install.sh" ]; then
bash "$INSTALL_DIR/scripts/post-install.sh"
fi

########################################
# Install CLI
########################################

install -m 755 "$INSTALL_DIR/scripts/media-stack" /usr/local/bin/media-stack

########################################
# Show dashboard
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo " Installation Complete"
echo "================================"

echo "Homepage Dashboard:"
echo "http://$IP:3001"

echo "Grafana Monitoring:"
echo "http://$IP:3000"