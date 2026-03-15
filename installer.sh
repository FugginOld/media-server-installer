#!/usr/bin/env bash
set -euo pipefail

########################################
# Resolve installer directory
########################################

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export INSTALL_DIR="$SCRIPT_ROOT"

########################################
# Load libraries
########################################

source "$INSTALL_DIR/lib/runtime.sh"
source "$INSTALL_DIR/lib/plugins.sh"
source "$INSTALL_DIR/lib/services.sh"
source "$INSTALL_DIR/lib/ports.sh"
source "$INSTALL_DIR/lib/compose.sh"

########################################
# Installer mode
########################################

MODE="install"
NONINTERACTIVE=0

if [[ "${1:-}" == "--validate" ]]; then
    MODE="validate"
    NONINTERACTIVE=1
    log "Running installer in validation mode"
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

review_gate() {

    if [[ "$NONINTERACTIVE" -eq 1 ]]; then
        return 0
    fi

    whiptail \
        --title "$1" \
        --yesno "$2" \
        14 60
}

progress_msg() {

    echo ""
    echo "================================"
    echo "$1"
    echo "================================"
    echo ""

}

########################################
# Platform initialization
########################################

require_root
detect_platform
detect_capabilities

########################################
# Preflight checks
########################################

bash "$SCRIPT_DIR/preflight.sh"

########################################
# Ensure Docker
########################################

ensure_docker

########################################
# Create stack directory
########################################

mkdir -p "$STACK_DIR"

progress_msg "Starting Media Stack Installer"

########################################
# Configuration wizard
########################################

if [[ "$NONINTERACTIVE" -eq 0 ]]; then
    run_configuration_wizard
fi

########################################
# Load saved configuration
########################################

if [[ -f "$STACK_DIR/stack.env" ]]; then
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
# Initialize registries
########################################

init_registry
init_port_registry

########################################
# Validate plugins
########################################

bash "$SCRIPT_DIR/plugin-validator.sh"

########################################
# Load plugins once (NEW)
########################################

load_plugins

########################################
# Discover plugins
########################################

AVAILABLE_PLUGINS=()
SELECTED_SERVICES=()

for plugin in "${!PLUGIN_PATHS[@]}"
do
    AVAILABLE_PLUGINS+=("$plugin")
done

########################################
# Service selection
########################################

OPTIONS=()
OPTIONS+=("ALL" "Install all services" OFF)

for plugin in "${AVAILABLE_PLUGINS[@]}"
do
    category=$(get_plugin_category "$plugin")
    OPTIONS+=("$plugin" "$category" OFF)
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

    if [[ "$service" == "ALL" ]]; then
        SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
        break
    fi

    SELECTED_SERVICES+=("$service")

done

########################################
# Dependency resolution
########################################

CHANGED=true

while [[ "$CHANGED" == true ]]
do

    CHANGED=false

    for SERVICE in "${SELECTED_SERVICES[@]}"
    do

        deps=$(get_plugin_dependencies "$SERVICE")

        for dep in $deps
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
# Validation mode
########################################

if [[ "$MODE" == "validate" ]]; then

    echo ""
    echo "Validation mode complete."
    printf " - %s\n" "${SELECTED_SERVICES[@]}"
    exit 0

fi

########################################
# Install review gate
########################################

SERVICE_SUMMARY=$(printf "%s\n" "${SELECTED_SERVICES[@]}")

review_gate \
"Install Services" \
"The following services will be installed:

$SERVICE_SUMMARY

Proceed with installation?" || exit 0

########################################
# Port conflict check
########################################

bash "$SCRIPT_DIR/port-check.sh"

########################################
# Generate docker compose
########################################

TMP_COMPOSE="$STACK_DIR/docker-compose.tmp"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

{
echo "networks:"
echo "  media-network:"
echo ""
echo "services:"
} > "$TMP_COMPOSE"

########################################
# Install services
########################################

progress_msg "Generating Docker Compose"

for SERVICE in "${SELECTED_SERVICES[@]}"
do

    log "Installing $SERVICE"

    PLUGIN_FILE=$(get_plugin_path "$SERVICE")
    source "$PLUGIN_FILE"

    install_service

done

mv "$TMP_COMPOSE" "$COMPOSE_FILE"

########################################
# Pull container images
########################################

progress_msg "Pulling container images"

images=$(docker compose -f "$COMPOSE_FILE" config | grep image | awk '{print $2}')

for img in $images
do
    log "Pulling $img"
    docker pull "$img"
done

########################################
# Start containers
########################################

progress_msg "Starting containers"

compose_up

########################################
# Container startup tracker
########################################

echo ""
echo "Waiting for containers to become healthy..."
sleep 5

docker compose -f "$COMPOSE_FILE" ps

########################################
# Post install
########################################

mkdir -p "$STACK_DIR/logs"

bash "$SCRIPT_DIR/post-install.sh" \
>> "$STACK_DIR/logs/post-install.log" 2>&1 &

########################################
# Completion
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
echo "Logs:"
echo "tail -f $STACK_DIR/logs/post-install.log"

echo ""
