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

PLUGIN_DIR="$INSTALL_DIR/plugins"

SELECTED_SERVICES=()
AVAILABLE_PLUGINS=()

########################################
# Run preflight checks
########################################

bash "$INSTALL_DIR/scripts/preflight.sh"

########################################
# Load core modules
########################################

source "$INSTALL_DIR/core/platform.sh"
source "$INSTALL_DIR/core/directories.sh"
source "$INSTALL_DIR/core/hardware.sh"
source "$INSTALL_DIR/core/docker.sh"
source "$INSTALL_DIR/core/config-wizard.sh"
source "$INSTALL_DIR/core/permissions.sh"

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
# WEB INSTALLER
########################################

if [ "$INTERFACE" = "web" ]; then

echo "Launching Web Installer..."

mkdir -p "$CONFIG_DIR/webinstaller"

cat <<EOF > "$STACK_DIR/docker-compose.yml"

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
echo "Open browser:"
echo "http://$IP:8088"
echo ""

exit 0

fi

########################################
# CLI INSTALLER
########################################

echo ""
echo "Starting Media Stack Custom Installer..."
echo ""

########################################
# Configuration wizard
########################################

run_configuration_wizard

########################################
# Load saved configuration
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Setup permissions
########################################

setup_permissions

########################################
# GPU detection
########################################

detect_gpu
configure_gpu_devices

########################################
# Initialize registries
########################################

source "$INSTALL_DIR/scripts/service-registry.sh"
init_registry

source "$INSTALL_DIR/scripts/port-registry.sh"
init_port_registry

########################################
# Validate plugins
########################################

source "$INSTALL_DIR/scripts/plugin-validator.sh"

########################################
# Discover plugins
########################################

discover_plugins() {

while IFS= read -r file
do

plugin=$(basename "$file" .sh)

if [ "$plugin" = "webinstaller" ]; then
continue
fi

AVAILABLE_PLUGINS+=("$plugin")

done < <(find "$PLUGIN_DIR" -type f -name "*.sh" ! -path "*/_template/*")

}

########################################
# Service selection
########################################

select_services() {

OPTIONS=()

OPTIONS+=("ALL" "Install all services" OFF)

for plugin in "${AVAILABLE_PLUGINS[@]}"
do

PLUGIN_FILE=$(find "$PLUGIN_DIR" -type f -name "$plugin.sh" | head -n 1)
source "$PLUGIN_FILE"

OPTIONS+=("$plugin" "$PLUGIN_CATEGORY" OFF)

done

CHOICES=$(whiptail \
--title "Media Stack Services" \
--checklist "Select services to install" \
22 70 15 \
"${OPTIONS[@]}" \
3>&1 1>&2 2>&3)

for service in $CHOICES
do

service="${service//\"/}"

if [ "$service" = "ALL" ]; then
SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
return
fi

SELECTED_SERVICES+=("$service")

done

}

########################################
# Dependency resolver
########################################

resolve_dependencies() {

CHANGED=true

while [ "$CHANGED" = true ]
do

CHANGED=false

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE=$(find "$PLUGIN_DIR" -type f -name "$SERVICE.sh" | head -n 1)

[ -f "$PLUGIN_FILE" ] || continue

source "$PLUGIN_FILE"

for dep in "${PLUGIN_DEPENDS[@]}"
do

if [[ ! " ${SELECTED_SERVICES[*]} " =~ " ${dep} " ]]; then
echo "Adding dependency: $dep"
SELECTED_SERVICES+=("$dep")
CHANGED=true
fi

done

done

done

}

########################################
# Plugin discovery
########################################

discover_plugins

if [ ${#AVAILABLE_PLUGINS[@]} -eq 0 ]; then
echo "No plugins discovered."
exit 1
fi

########################################
# Service selection
########################################

select_services

########################################
# Resolve dependencies
########################################

resolve_dependencies

SELECTED_SERVICES=($(printf "%s\n" "${SELECTED_SERVICES[@]}" | sort -u))

########################################
# Generate docker compose
########################################

TMP_COMPOSE="$STACK_DIR/docker-compose.tmp"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

cat <<EOF > "$TMP_COMPOSE"

networks:
  media-network:

services:

EOF

########################################
# Install services
########################################

echo ""
echo "Installing services..."
echo ""

for SERVICE in "${SELECTED_SERVICES[@]}"
do

echo "Installing $SERVICE"

PLUGIN_FILE=$(find "$PLUGIN_DIR" -type f -name "$SERVICE.sh" | head -n 1)

if [ ! -f "$PLUGIN_FILE" ]; then
echo "Plugin missing: $SERVICE"
continue
fi

source "$PLUGIN_FILE"

install_service

done

mv "$TMP_COMPOSE" "$COMPOSE_FILE"

########################################
# Start containers
########################################

bash "$INSTALL_DIR/scripts/compose.sh" up

########################################
# Run post-install in background
########################################

mkdir -p "$STACK_DIR/logs"

bash "$INSTALL_DIR/scripts/post-install.sh" \
>> "$STACK_DIR/logs/post-install.log" 2>&1 &

########################################
# Completion message
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo " Installation Complete"
echo "================================"
echo ""

echo "Media services are starting."

echo ""
echo "Homepage:"
echo "http://$IP:3001"
echo ""

echo "Grafana:"
echo "http://$IP:3000"
echo ""

echo "Background setup running."
echo "View progress with:"
echo ""
echo "tail -f /opt/media-stack/logs/post-install.log"
echo ""

echo "Run CLI:"
echo "media-stack"
echo ""
