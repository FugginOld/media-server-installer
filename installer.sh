#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

cd "$INSTALL_DIR"

########################################
# Installer mode
########################################

INSTALL_MODE="install"
NONINTERACTIVE=0

if [ "${1:-}" = "--validate" ]; then
INSTALL_MODE="validate"
NONINTERACTIVE=1
echo "Running installer in validation mode."
fi

########################################
# Load core modules
########################################

source "$CORE_DIR/platform.sh"
source "$CORE_DIR/capabilities.sh"
source "$CORE_DIR/directories.sh"
source "$CORE_DIR/hardware.sh"
source "$CORE_DIR/docker.sh"
source "$CORE_DIR/config-wizard.sh"
source "$CORE_DIR/permissions.sh"

########################################
# UI helpers
########################################

confirm_gate() {

if [ "$NONINTERACTIVE" -eq 1 ]; then
return 0
fi

whiptail \
--title "$1" \
--yesno "$2" \
12 60

}

progress_update() {

CURRENT="$1"
TOTAL="$2"
MSG="$3"

PERCENT=$((CURRENT * 100 / TOTAL))

echo "$PERCENT" | whiptail --gauge "$MSG" 6 60 0

}

########################################
# Platform initialization
########################################

require_root
detect_platform
detect_capabilities

########################################
# Run preflight
########################################

bash "$SCRIPT_DIR/preflight.sh"

########################################
# System review gate
########################################

SYSTEM_SUMMARY=$(cat <<EOF
Platform: $PLATFORM_ID
Family: $PLATFORM_FAMILY
Architecture: $(uname -m)

Filesystem: $CAP_FILESYSTEM
GPU: $CAP_GPU

Continue with installation?
EOF
)

confirm_gate "System Review" "$SYSTEM_SUMMARY" || exit 0

########################################
# Ensure docker
########################################

ensure_docker

########################################
# Create stack directory
########################################

mkdir -p "$STACK_DIR"

########################################
# Installer interface selection
########################################

if [ "$NONINTERACTIVE" -eq 1 ]; then
INTERFACE="cli"
else
INTERFACE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation interface" \
15 60 2 \
cli "CLI Installer" \
web "Web Installer" \
3>&1 1>&2 2>&3)
fi

########################################
# Web installer
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
# CLI installer
########################################

echo ""
echo "Starting Media Stack Custom Installer..."
echo ""

########################################
# Configuration wizard
########################################

if [ "$NONINTERACTIVE" -eq 0 ]; then
run_configuration_wizard
fi

########################################
# Configuration review gate
########################################

CONFIG_REVIEW=$(cat <<EOF
Stack directory: $STACK_DIR
Config directory: $CONFIG_DIR

Continue with these settings?
EOF
)

confirm_gate "Configuration Review" "$CONFIG_REVIEW" || exit 0

########################################
# Load saved config
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Setup permissions
########################################

setup_permissions

########################################
# Hardware detection
########################################

detect_gpu
configure_gpu_devices

########################################
# Registries
########################################

source "$SCRIPT_DIR/service-registry.sh"
init_registry

source "$SCRIPT_DIR/port-registry.sh"
init_port_registry

########################################
# Plugin validation
########################################

bash "$SCRIPT_DIR/plugin-validator.sh"

########################################
# Plugin discovery
########################################

AVAILABLE_PLUGINS=()
SELECTED_SERVICES=()
declare -A PLUGIN_PATHS

while IFS= read -r file
do

plugin=$(basename "$file" .sh)

AVAILABLE_PLUGINS+=("$plugin")
PLUGIN_PATHS["$plugin"]="$file"

done < <(
find "$PLUGIN_DIR" -type f -name "*.sh" \
! -path "*/_template/*" \
! -name "webinstaller.sh" | sort
)

########################################
# Plugin discovery gate
########################################

PLUGIN_LIST=$(printf "%s\n" "${AVAILABLE_PLUGINS[@]}")

confirm_gate \
"Plugin Discovery" \
"Plugins detected:

$PLUGIN_LIST

Continue?" || exit 0

########################################
# Service selection
########################################

if [ "$NONINTERACTIVE" -eq 1 ]; then
SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
else

OPTIONS=()
OPTIONS+=("ALL" "Install all services" OFF)

for plugin in "${AVAILABLE_PLUGINS[@]}"
do

PLUGIN_FILE="${PLUGIN_PATHS[$plugin]}"
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
break
fi

SELECTED_SERVICES+=("$service")

done

fi

########################################
# Dependency resolver
########################################

CHANGED=true

while [ "$CHANGED" = true ]
do

CHANGED=false

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"
source "$PLUGIN_FILE"

for dep in "${PLUGIN_DEPENDS[@]}"
do

if [[ ! " ${SELECTED_SERVICES[*]} " =~ " ${dep} " ]]; then
SELECTED_SERVICES+=("$dep")
CHANGED=true
fi

done

done

done

SELECTED_SERVICES=($(printf "%s\n" "${SELECTED_SERVICES[@]}" | sort -u))

########################################
# Validation mode exit
########################################

if [ "$INSTALL_MODE" = "validate" ]; then

echo ""
echo "Validation mode complete."
echo "Services that would be installed:"
printf " - %s\n" "${SELECTED_SERVICES[@]}"
echo ""
exit 0

fi

########################################
# Final install gate
########################################

SERVICE_SUMMARY=$(printf "%s\n" "${SELECTED_SERVICES[@]}")

confirm_gate \
"Install Services" \
"The following services will be installed:

$SERVICE_SUMMARY

Proceed?" || exit 0

########################################
# Port conflict detection
########################################

source "$SCRIPT_DIR/port-check.sh"

########################################
# Parallel image pulling
########################################

MAX_PULLS=4

echo ""
echo "Pulling container images..."

IMAGES=()

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"
source "$PLUGIN_FILE"

IMAGES+=("$DOCKER_IMAGE")

done

IMAGES=($(printf "%s\n" "${IMAGES[@]}" | sort -u))

PIDS=()
COUNT=0

for IMAGE in "${IMAGES[@]}"
do

docker pull "$IMAGE" &

PIDS+=($!)
COUNT=$((COUNT+1))

if [ "$COUNT" -ge "$MAX_PULLS" ]; then
wait "${PIDS[@]}"
PIDS=()
COUNT=0
fi

done

wait

########################################
# Compose generation
########################################

TMP_COMPOSE="$STACK_DIR/docker-compose.tmp"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

cat <<EOF > "$TMP_COMPOSE"
networks:
  media-network:

services:
EOF

########################################
# Install services with progress
########################################

TOTAL=${#SELECTED_SERVICES[@]}
CURRENT=0

for SERVICE in "${SELECTED_SERVICES[@]}"
do

CURRENT=$((CURRENT+1))

progress_update "$CURRENT" "$TOTAL" "Installing $SERVICE"

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"
source "$PLUGIN_FILE"

install_service

done

mv "$TMP_COMPOSE" "$COMPOSE_FILE"

########################################
# Start containers
########################################

bash "$SCRIPT_DIR/compose.sh" up

########################################
# Container startup tracker
########################################

echo "Waiting for containers to start..."

MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]
do

RUNNING=$(docker ps --format '{{.Names}}' | wc -l)
TOTAL=$(docker compose ps --services | wc -l)

if [ "$RUNNING" -ge "$TOTAL" ]; then
echo "All containers running."
break
fi

sleep 3
WAITED=$((WAITED+3))

done

########################################
# Run post-install tasks
########################################

mkdir -p "$STACK_DIR/logs"

bash "$SCRIPT_DIR/post-install.sh" \
>> "$STACK_DIR/logs/post-install.log" 2>&1 &

########################################
# Completion message
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo "Installation Complete"
echo "================================"
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
echo "tail -f $STACK_DIR/logs/post-install.log"
echo ""

echo "Run CLI:"
echo "media-stack"
echo ""
