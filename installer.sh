#!/usr/bin/env bash

set -e

########################################
# Media Stack Installer
########################################

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"
PLUGIN_DIR="./plugins"

SELECTED_SERVICES=()

########################################
# Run preflight checks
########################################

bash ./scripts/preflight.sh

########################################
# Load core modules
########################################

source ./core/platform.sh
source ./core/directories.sh
source ./core/hardware.sh
source ./core/docker.sh
source ./core/config-wizard.sh
source ./core/permissions.sh

########################################
# Detect platform
########################################

detect_platform

########################################
# Ensure Docker installed
########################################

ensure_docker

########################################
# Create stack directory
########################################

mkdir -p "$STACK_DIR"

########################################
# Select installer interface
########################################

INTERFACE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation interface" \
15 60 2 \
cli "CLI Installer" \
web "Web Installer" \
3>&1 1>&2 2>&3)

########################################
# WEB INSTALLER MODE
########################################

if [ "$INTERFACE" = "web" ]; then

echo ""
echo "Launching Web Installer..."
echo ""

mkdir -p "$STACK_DIR/config/webinstaller"

cat <<EOF > "$STACK_DIR/docker-compose.yml"
version: "3.9"

services:

  webinstaller:
    image: nginx:alpine
    container_name: webinstaller
    ports:
      - "8088:80"
    volumes:
      - ./config/webinstaller:/usr/share/nginx/html
    restart: unless-stopped
EOF

cd "$STACK_DIR"

docker compose up -d

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo " Media Stack Web Installer"
echo "================================"
echo ""
echo "Open your browser:"
echo ""
echo "http://$IP:8088"
echo ""

exit 0

fi

########################################
# CLI INSTALLER MODE
########################################

echo ""
echo "Starting CLI installer..."
echo ""

########################################
# Run configuration wizard
########################################

run_configuration_wizard

########################################
# Load configuration
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Setup permissions (NAS compatible)
########################################

setup_permissions

########################################
# Detect GPU hardware
########################################

detect_gpu
configure_gpu_devices

########################################
# Initialize registries
########################################

source ./scripts/service-registry.sh
init_registry

source ./scripts/port-registry.sh
init_port_registry

########################################
# Validate plugins
########################################

bash ./scripts/plugin-validator.sh

########################################
# Discover plugins automatically
########################################

discover_plugins() {

AVAILABLE_PLUGINS=()

for file in $(find "$PLUGIN_DIR" -name "*.sh")
do
    plugin=$(basename "$file" .sh)
    AVAILABLE_PLUGINS+=("$plugin")
done

}

########################################
# Service selection menu
########################################

select_services() {

OPTIONS=()

for plugin in "${AVAILABLE_PLUGINS[@]}"
do
    OPTIONS+=("$plugin" "")
done

CHOICES=$(whiptail \
--title "Media Stack Services" \
--checklist "Select services to install" \
20 70 15 \
"${OPTIONS[@]}" \
3>&1 1>&2 2>&3)

for service in $CHOICES
do
    SELECTED_SERVICES+=("${service//\"/}")
done

}

########################################
# Dependency resolver
########################################

resolve_dependencies() {

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE=$(find "$PLUGIN_DIR" -name "$SERVICE.sh")

source "$PLUGIN_FILE"

for dep in "${PLUGIN_DEPENDS[@]}"
do

if [[ ! " ${SELECTED_SERVICES[@]} " =~ " ${dep} " ]]; then

echo "Adding dependency: $dep"

SELECTED_SERVICES+=("$dep")

fi

done

done

}

########################################
# Installation mode
########################################

MODE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation mode" \
15 60 2 \
quick "Recommended stack" \
custom "Choose services manually" \
3>&1 1>&2 2>&3)

########################################
# Quick install preset
########################################

if [ "$MODE" = "quick" ]; then

SELECTED_SERVICES=(
plex
radarr
sonarr
prowlarr
bazarr
overseerr
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
glances
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
# Generate docker compose file
########################################

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

cat <<EOF > "$COMPOSE_FILE"
version: "3.9"

networks:
  media-network:

services:

EOF

########################################
# Install selected plugins
########################################

echo ""
echo "Installing services..."
echo ""

for SERVICE in "${SELECTED_SERVICES[@]}"
do

echo "Installing $SERVICE"

PLUGIN_FILE=$(find "$PLUGIN_DIR" -name "$SERVICE.sh")

source "$PLUGIN_FILE"

install_service

done

########################################
# Start containers
########################################

bash ./scripts/compose.sh up

########################################
# Post install automation
########################################

if [ -f ./scripts/post-install.sh ]; then
bash ./scripts/post-install.sh
fi

########################################
# Display completion message
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo " Installation Complete"
echo "================================"
echo ""

echo "Homepage Dashboard:"
echo "http://$IP:3001"
echo ""

echo "Grafana Monitoring:"
echo "http://$IP:3000"
echo ""

echo "Run CLI with:"
echo ""
echo "media-stack"
echo ""