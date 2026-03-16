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

# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/runtime.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/plugins.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/services.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/ports.sh"
# shellcheck disable=SC1091
source "$INSTALL_DIR/lib/compose.sh"

########################################
# Plugin validation
########################################

validate_plugin_file() {
    local file="$1"
    local perm=""
    local last_digit=""
    
    # Check file exists and is readable
    [[ -r "$file" ]] || { error "Plugin not readable: $file"; return 1; }
    
    # Check file is not writable by others (prevent tampering)
    if command -v stat >/dev/null 2>&1; then
        perm="$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null || true)"

        if [[ -n "$perm" ]]; then
            last_digit="${perm: -1}"
            case "$last_digit" in
                2|3|6|7)
                    error "Plugin is world-writable: $file"
                    return 1
                    ;;
            esac
        else
            warn "Could not determine plugin permissions with stat: $file"
        fi
    fi
    
    # Check for suspicious patterns before sourcing
    if grep -q 'rm -rf\|:(){:\|:(){ :;}\|sudo false' "$file" 2>/dev/null; then
        error "Plugin contains suspicious code: $file"
        return 1
    fi
    
    return 0
}

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

# shellcheck disable=SC1091
source "$CORE_DIR/platform.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/capabilities.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/directories.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/hardware.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/docker.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/env.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/config-wizard.sh"
# shellcheck disable=SC1091
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

get_dialog_size() {
    local rows="${LINES:-}"
    local cols="${COLUMNS:-}"

    if [[ -z "$rows" || -z "$cols" ]]; then
        if command -v tput >/dev/null 2>&1; then
            rows="$(tput lines 2>/dev/null || echo 24)"
            cols="$(tput cols 2>/dev/null || echo 80)"
        else
            rows=24
            cols=80
        fi
    fi

    DIALOG_HEIGHT=$((rows - 4))
    DIALOG_WIDTH=$((cols - 6))

    (( DIALOG_HEIGHT < 16 )) && DIALOG_HEIGHT=16
    (( DIALOG_WIDTH < 60 )) && DIALOG_WIDTH=60
    (( DIALOG_HEIGHT > 40 )) && DIALOG_HEIGHT=40
    (( DIALOG_WIDTH > 140 )) && DIALOG_WIDTH=140
}

show_install_preview() {
    local summary="$1"
    local tmp_preview

    [[ "$NONINTERACTIVE" -eq 1 ]] && return 0

    get_dialog_size

    tmp_preview="$(mktemp -p "$STACK_DIR" -t install-preview.XXXXXX)"

    {
        echo "The following services will be installed:"
        echo ""
        printf "%s\n" "$summary"
    } > "$tmp_preview"

    whiptail \
        --title "Install Services" \
        --scrolltext \
        --textbox "$tmp_preview" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH"

    rm -f "$tmp_preview"
}

progress_msg() {

    echo ""
    echo "================================"
    echo "$1"
    echo "================================"
    echo ""

}

array_contains() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done

    return 1
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
    # shellcheck disable=SC1091
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

if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
else
    CHOICES=$(whiptail \
        --title "Media Stack Services" \
        --checklist "Select services to install" \
        22 70 15 \
        "${OPTIONS[@]}" \
        3>&1 1>&2 2>&3)

    if [[ "$CHOICES" == *'"ALL"'* ]]; then
        SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
    else
        mapfile -t SELECTED_SERVICES < <(
            printf "%s\n" "$CHOICES" \
            | tr ' ' '\n' \
            | sed 's/^"//; s/"$//' \
            | awk 'NF'
        )
    fi
fi

########################################
# Dependency resolution
########################################

CHANGED=true
MAX_DEP_PASSES=50
DEP_PASS=0

while [[ "$CHANGED" == true ]]
do

    ((++DEP_PASS))
    if (( DEP_PASS > MAX_DEP_PASSES )); then
        error "Dependency resolution exceeded ${MAX_DEP_PASSES} passes. Possible circular dependency."
        exit 1
    fi

    CHANGED=false

    for SERVICE in "${SELECTED_SERVICES[@]}"
    do

        if [[ -z "${PLUGIN_PATHS[$SERVICE]:-}" ]]; then
            error "Unknown selected service '$SERVICE'"
            exit 1
        fi

        deps="$(get_plugin_dependencies "$SERVICE")"
        read -r -a dep_list <<< "$deps"

        for dep in "${dep_list[@]}"
        do
            [[ -z "$dep" ]] && continue

            if [[ -z "${PLUGIN_PATHS[$dep]:-}" ]]; then
                error "Unknown dependency '$dep' required by '$SERVICE'"
                exit 1
            fi

            if ! array_contains "$dep" "${SELECTED_SERVICES[@]}"; then
                SELECTED_SERVICES+=("$dep")
                CHANGED=true
            fi
        done

    done

done

mapfile -t SELECTED_SERVICES < <(printf "%s\n" "${SELECTED_SERVICES[@]}" | awk 'NF' | sort -u)

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

show_install_preview "$SERVICE_SUMMARY"

review_gate \
"Install Services" \
"Proceed with installation?" || exit 0

########################################
# Port conflict check
########################################

bash "$SCRIPT_DIR/port-check.sh" "${SELECTED_SERVICES[@]}"

########################################
# Generate docker compose
########################################

TMP_COMPOSE="$(mktemp -p "$STACK_DIR" -t docker-compose.XXXXXX)"
trap 'rm -f "$TMP_COMPOSE"' EXIT
chmod 600 "$TMP_COMPOSE"
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
    validate_plugin_file "$PLUGIN_FILE" || exit 1
    # shellcheck disable=SC1090
    source "$PLUGIN_FILE"

    install_service

done

# Validate the generated compose file
if ! docker compose -f "$TMP_COMPOSE" config >/dev/null 2>&1; then
    error "Generated invalid docker-compose.yml"
    exit 1
fi

mv "$TMP_COMPOSE" "$COMPOSE_FILE"

########################################
# Pull container images
########################################

progress_msg "Pulling container images"

if ! images="$(docker compose -f "$COMPOSE_FILE" config --format json 2>/dev/null | jq -r '.services[]?.image // empty')"; then
    images=""
fi

if [[ -z "$images" ]]; then
    images="$(docker compose -f "$COMPOSE_FILE" config 2>/dev/null | awk '/^[[:space:]]*image:/ {print $2}')"
fi

if [[ -z "$images" ]]; then
    error "Failed to get image list from compose file"
    exit 1
fi

while IFS= read -r img; do
    [[ -n "$img" ]] && {
        log "Pulling $img"
        docker pull "$img" || error "Failed to pull image: $img"
    }
done <<< "$images"

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
