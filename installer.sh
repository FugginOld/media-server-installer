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
INSTALLER_FRONTEND="web"
WEB_SESSION_PORT=8099
WEB_SESSION_DIR=""
WEB_CONFIG_DEFAULTS_FILE=""
WEB_CONFIG_FILE=""
WEB_SELECTION_FILE=""
WEB_PROGRESS_FILE=""
WEB_PLUGINS_FILE=""
WEB_SERVER_PID=""

if [[ "${1:-}" == "--validate" ]]; then
    MODE="validate"
    NONINTERACTIVE=1
    log "Running installer in validation mode"
fi

if [[ -n "${MEDIA_STACK_INSTALLER_FRONTEND:-}" ]]; then
    case "$MEDIA_STACK_INSTALLER_FRONTEND" in
        cli|web)
            INSTALLER_FRONTEND="$MEDIA_STACK_INSTALLER_FRONTEND"
            ;;
        *)
            warn "Ignoring invalid MEDIA_STACK_INSTALLER_FRONTEND='$MEDIA_STACK_INSTALLER_FRONTEND' (expected: cli|web)"
            ;;
    esac
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
    [[ "$INSTALLER_FRONTEND" == "web" ]] && return 0

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

cleanup_web_session() {
    if [[ -n "$WEB_SERVER_PID" ]]; then
        kill "$WEB_SERVER_PID" >/dev/null 2>&1 || true
        wait "$WEB_SERVER_PID" 2>/dev/null || true
        WEB_SERVER_PID=""
    fi
}

web_progress_set_phase() {
    local phase="$1"
    local message="$2"
    local tmp=""

    [[ "$INSTALLER_FRONTEND" != "web" ]] && return 0
    [[ -z "$WEB_PROGRESS_FILE" || ! -f "$WEB_PROGRESS_FILE" ]] && return 0

    tmp="$(mktemp -p "$STACK_DIR" -t web-progress.XXXXXX)"
    if jq --arg phase "$phase" --arg message "$message" '.phase=$phase | .message=$message | .updatedAt=(now|floor)' "$WEB_PROGRESS_FILE" > "$tmp"; then
        mv "$tmp" "$WEB_PROGRESS_FILE"
    else
        rm -f "$tmp"
    fi
}

web_progress_set_service() {
    local name="$1"
    local status="$2"
    local note="$3"
    local tmp=""

    [[ "$INSTALLER_FRONTEND" != "web" ]] && return 0
    [[ -z "$WEB_PROGRESS_FILE" || ! -f "$WEB_PROGRESS_FILE" ]] && return 0

    tmp="$(mktemp -p "$STACK_DIR" -t web-progress.XXXXXX)"
    if jq --arg name "$name" --arg status "$status" --arg note "$note" '
        .services = (
            if (.services | any(.name == $name)) then
                (.services | map(if .name==$name then .status=$status | .note=$note else . end))
            else
                (.services + [{name:$name,status:$status,note:$note}])
            end
        )
        | .updatedAt=(now|floor)
    ' "$WEB_PROGRESS_FILE" > "$tmp"; then
        mv "$tmp" "$WEB_PROGRESS_FILE"
    else
        rm -f "$tmp"
    fi
}

start_web_selection_server() {
    local plugin_json='[]'
    local plugin
    local category
    local default_selected

    WEB_SESSION_DIR="$STACK_DIR/web-installer-session"
    WEB_CONFIG_DEFAULTS_FILE="$WEB_SESSION_DIR/config-defaults.json"
    WEB_CONFIG_FILE="$WEB_SESSION_DIR/config.json"
    WEB_SELECTION_FILE="$WEB_SESSION_DIR/selection.json"
    WEB_PROGRESS_FILE="$WEB_SESSION_DIR/progress.json"
    WEB_PLUGINS_FILE="$WEB_SESSION_DIR/plugins.json"

    mkdir -p "$WEB_SESSION_DIR" "$STACK_DIR/logs"
    cleanup_web_session
    rm -f "$WEB_SELECTION_FILE"

    for plugin in "${AVAILABLE_PLUGINS[@]}"; do
        category="$(get_plugin_category "$plugin")"
        default_selected=false
        [[ "$plugin" == "webinstaller" ]] && default_selected=true

        plugin_json="$(jq -c --arg name "$plugin" --arg category "$category" --argjson defaultSelected "$default_selected" '. + [{name:$name,category:$category,defaultSelected:$defaultSelected}]' <<< "$plugin_json")"
    done

    jq -n --argjson plugins "$plugin_json" '{plugins:$plugins}' > "$WEB_PLUGINS_FILE"
    if [[ ! -f "$WEB_CONFIG_DEFAULTS_FILE" ]]; then
        jq -n \
            --arg timezone "${TIMEZONE:-UTC}" \
            --arg puid "${PUID:-$(id -u)}" \
            --arg pgid "${PGID:-$(id -g)}" \
            --arg dockerNetwork "${DOCKER_NETWORK:-media-network}" \
            --arg dirMode "${DIR_MODE:-default}" \
            '{timezone:$timezone,puid:$puid,pgid:$pgid,dockerNetwork:$dockerNetwork,dirMode:$dirMode}' > "$WEB_CONFIG_DEFAULTS_FILE"
    fi
    jq -n '{phase:"waiting_selection",message:"Waiting for plugin selection from web UI...",services:[],updatedAt:(now|floor)}' > "$WEB_PROGRESS_FILE"

    python3 "$SCRIPT_DIR/web-installer-server.py" \
        --session-dir "$WEB_SESSION_DIR" \
        --host 0.0.0.0 \
        --port "$WEB_SESSION_PORT" \
        --host-ip "$HOST_IP" \
        > "$STACK_DIR/logs/web-installer.log" 2>&1 &
    WEB_SERVER_PID="$!"

    sleep 1
    if ! kill -0 "$WEB_SERVER_PID" >/dev/null 2>&1; then
        error "Failed to start web installer server"
        return 1
    fi

    echo ""
    echo "Web Installer URL (open this in your browser):"
    print_modern_link "http://${HOST_IP}:${WEB_SESSION_PORT}"
    echo ""
    echo "Waiting for plugin selection from web UI..."

    while [[ ! -f "$WEB_SELECTION_FILE" ]]; do
        sleep 1
    done

    if jq -e '.all == true' "$WEB_SELECTION_FILE" >/dev/null 2>&1; then
        SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
    else
        mapfile -t SELECTED_SERVICES < <(jq -r '.selected[]?' "$WEB_SELECTION_FILE")
    fi

    if [[ "${#SELECTED_SERVICES[@]}" -eq 0 ]]; then
        warn "No plugins selected from web UI; defaulting to webinstaller"
        SELECTED_SERVICES=("webinstaller")
    fi

    if ! array_contains "webinstaller" "${SELECTED_SERVICES[@]}"; then
        SELECTED_SERVICES+=("webinstaller")
    fi
}

start_web_config_server() {
    local default_tz
    local default_uid
    local default_gid
    local default_network
    local default_dir_mode

    WEB_SESSION_DIR="$STACK_DIR/web-installer-session"
    WEB_CONFIG_DEFAULTS_FILE="$WEB_SESSION_DIR/config-defaults.json"
    WEB_CONFIG_FILE="$WEB_SESSION_DIR/config.json"
    WEB_SELECTION_FILE="$WEB_SESSION_DIR/selection.json"
    WEB_PROGRESS_FILE="$WEB_SESSION_DIR/progress.json"
    WEB_PLUGINS_FILE="$WEB_SESSION_DIR/plugins.json"

    mkdir -p "$WEB_SESSION_DIR" "$STACK_DIR/logs"
    cleanup_web_session

    default_tz="${TIMEZONE:-$(timedatectl show --property=Timezone --value 2>/dev/null || true)}"
    default_tz="${default_tz:-UTC}"
    default_uid="${PUID:-$(id -u)}"
    default_gid="${PGID:-$(id -g)}"
    default_network="${DOCKER_NETWORK:-media-network}"
    default_dir_mode="${DIR_MODE:-default}"

    rm -f "$WEB_CONFIG_FILE" "$WEB_SELECTION_FILE"

    jq -n \
        --arg timezone "$default_tz" \
        --arg puid "$default_uid" \
        --arg pgid "$default_gid" \
        --arg dockerNetwork "$default_network" \
        --arg dirMode "$default_dir_mode" \
        '{timezone:$timezone,puid:$puid,pgid:$pgid,dockerNetwork:$dockerNetwork,dirMode:$dirMode}' > "$WEB_CONFIG_DEFAULTS_FILE"

    jq -n '{plugins:[]}' > "$WEB_PLUGINS_FILE"
    jq -n '{phase:"waiting_config",message:"Waiting for configuration from web UI...",services:[],updatedAt:(now|floor)}' > "$WEB_PROGRESS_FILE"

    python3 "$SCRIPT_DIR/web-installer-server.py" \
        --session-dir "$WEB_SESSION_DIR" \
        --host 0.0.0.0 \
        --port "$WEB_SESSION_PORT" \
        --host-ip "$HOST_IP" \
        > "$STACK_DIR/logs/web-installer.log" 2>&1 &
    WEB_SERVER_PID="$!"

    sleep 1
    if ! kill -0 "$WEB_SERVER_PID" >/dev/null 2>&1; then
        error "Failed to start web installer server"
        return 1
    fi

    echo ""
    echo "Web Installer URL (open this in your browser):"
    print_modern_link "http://${HOST_IP}:${WEB_SESSION_PORT}"
    echo ""
    echo "Waiting for web configuration (timezone, PUID, PGID, Docker network, directory mode)..."

    while [[ ! -f "$WEB_CONFIG_FILE" ]]; do
        sleep 1
    done

    TIMEZONE="$(jq -r '.timezone // empty' "$WEB_CONFIG_FILE" 2>/dev/null)"
    PUID="$(jq -r '.puid // empty' "$WEB_CONFIG_FILE" 2>/dev/null)"
    PGID="$(jq -r '.pgid // empty' "$WEB_CONFIG_FILE" 2>/dev/null)"
    DOCKER_NETWORK="$(jq -r '.dockerNetwork // empty' "$WEB_CONFIG_FILE" 2>/dev/null)"
    DIR_MODE="$(jq -r '.dirMode // empty' "$WEB_CONFIG_FILE" 2>/dev/null)"

    [[ -z "$TIMEZONE" ]] && TIMEZONE="$default_tz"
    [[ ! "$PUID" =~ ^[0-9]+$ || "$PUID" -gt 65535 ]] && PUID="$default_uid"
    [[ ! "$PGID" =~ ^[0-9]+$ || "$PGID" -gt 65535 ]] && PGID="$default_gid"
    [[ -z "$DOCKER_NETWORK" ]] && DOCKER_NETWORK="$default_network"
    if [[ "$DIR_MODE" != "default" && "$DIR_MODE" != "trash" ]]; then
        DIR_MODE="$default_dir_mode"
    fi

    cat <<EOF > "$STACK_DIR/stack.env"
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
DOCKER_NETWORK=$DOCKER_NETWORK
DIR_MODE=$DIR_MODE
EOF

    cleanup_web_session
}

init_web_progress() {
    local services_json='[]'
    local svc

    [[ "$INSTALLER_FRONTEND" != "web" ]] && return 0
    [[ -z "$WEB_PROGRESS_FILE" ]] && return 0

    # High-level lifecycle gates shown in the web UI.
    services_json="$(jq -c '. + [{name:"Stage: Plugin Install",status:"pending",note:"Queued"}]' <<< "$services_json")"
    services_json="$(jq -c '. + [{name:"Stage: Compose Validate",status:"pending",note:"Queued"}]' <<< "$services_json")"
    services_json="$(jq -c '. + [{name:"Stage: Pull Images",status:"pending",note:"Queued"}]' <<< "$services_json")"
    services_json="$(jq -c '. + [{name:"Stage: Start Containers",status:"pending",note:"Queued"}]' <<< "$services_json")"
    services_json="$(jq -c '. + [{name:"Stage: Post Install",status:"pending",note:"Queued"}]' <<< "$services_json")"

    for svc in "${SELECTED_SERVICES[@]}"; do
        services_json="$(jq -c --arg name "$svc" '. + [{name:$name,status:"pending",note:"Queued"}]' <<< "$services_json")"
    done

    jq -n --argjson services "$services_json" '{phase:"installing",message:"Installation started",services:$services,updatedAt:(now|floor)}' > "$WEB_PROGRESS_FILE"
}

select_installer_frontend() {

    if [[ "$NONINTERACTIVE" -eq 1 ]]; then
        return 0
    fi

    if [[ -n "${MEDIA_STACK_INSTALLER_FRONTEND:-}" ]]; then
        return 0
    fi

    local choice=""

    choice=$(whiptail \
        --title "Installer Mode" \
        --radiolist "Choose installer frontend" \
        14 70 4 \
        "cli" "CLI Installer (interactive terminal flow)" OFF \
        "web" "Web Installer (includes browser-based UI service)" ON \
        3>&1 1>&2 2>&3) || exit 0

    [[ -n "$choice" ]] && INSTALLER_FRONTEND="$choice"
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

print_modern_link() {
    local url="$1"

    # OSC 8 hyperlinks are supported by modern terminal emulators (xterm.js/noVNC, iTerm2, etc.).
    if [[ -t 1 ]]; then
        printf '\e]8;;%s\a%s\e]8;;\a\n' "$url" "$url"
    else
        echo "$url"
    fi
}

service_url_reachable() {
    local url="$1"

    curl -fsS --max-time 3 "$url" >/dev/null 2>&1
}

service_url_reachable_with_retry() {
    local url="$1"
    local attempts="${2:-5}"
    local delay="${3:-1}"
    local i

    for ((i=1; i<=attempts; i++)); do
        if service_url_reachable "$url"; then
            return 0
        fi

        (( i < attempts )) && sleep "$delay"
    done

    return 1
}

service_startup_retry_attempts() {
    local name="$1"

    case "$name" in
        "Bazarr")
            echo 30
            ;;
        "Overseerr"|"Radarr")
            echo 20
            ;;
        *)
            echo 5
            ;;
    esac
}

wait_for_service_with_countdown() {
    local name="$1"
    local url="$2"
    local timeout=60
    local remaining

    if service_url_reachable "$url"; then
        echo " - $name: ready"
        return 0
    fi

    for ((remaining=timeout; remaining>0; remaining-=2)); do
        printf '\r - %s: waiting... %2ss remaining' "$name" "$remaining"

        if service_url_reachable "$url"; then
            printf '\r - %s: ready.                    \n' "$name"
            return 0
        fi

        sleep 2
    done

    if service_url_reachable "$url"; then
        printf '\r - %s: ready.                    \n' "$name"
        return 0
    fi

    printf '\r - %s: timed out after %ss.      \n' "$name" "$timeout"
    return 1
}

show_installed_services() {
    local entry
    local name
    local url
    local attempts
    local -a ui_entries=()

    if [[ ! -f "$SERVICE_REGISTRY" ]] || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    mapfile -t INSTALLED_ENTRIES < <(jq -r '.services[]? | "\(.name)|\(.url)"' "$SERVICE_REGISTRY")
    if [[ "${#INSTALLED_ENTRIES[@]}" -eq 0 ]]; then
        return 1
    fi

    echo "Installed Services:"
    for entry in "${INSTALLED_ENTRIES[@]}"; do
        name="${entry%%|*}"
        url="${entry#*|}"

        [[ -z "$name" || -z "$url" ]] && continue
        [[ "$name" == "Web Installer" ]] && continue

        case "$name" in
            "Homepage"|"Grafana")
                ui_entries+=("$entry")
                continue
                ;;
        esac

        printf " - %s: " "$name"
        attempts="$(service_startup_retry_attempts "$name")"

        if service_url_reachable_with_retry "$url" "$attempts" 1; then
            print_modern_link "$url"
        else
            print_modern_link "$url"
            echo "   [WARN] Service not reachable yet. Check container status: docker compose -f $COMPOSE_FILE ps"
        fi
    done

    if (( ${#ui_entries[@]} > 0 )); then
        echo ""
        echo "Waiting for Homepage and Grafana:"

        for entry in "${ui_entries[@]}"; do
            name="${entry%%|*}"
            url="${entry#*|}"

            wait_for_service_with_countdown "$name" "$url" || true
            printf " - %s: " "$name"
            print_modern_link "$url"

            if ! service_url_reachable_with_retry "$url" 3 1; then
                echo "   [WARN] Service not reachable yet. Check container status: docker compose -f $COMPOSE_FILE ps"
            fi
        done
    fi

    return 0
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
# Installer frontend selection
########################################

select_installer_frontend

if [[ "$INSTALLER_FRONTEND" == "web" ]]; then
    log "Installer frontend: Web Installer"
else
    log "Installer frontend: CLI Installer"
fi

########################################
# Configuration wizard
########################################

if [[ "$NONINTERACTIVE" -eq 0 ]]; then
    if [[ "$INSTALLER_FRONTEND" == "web" ]]; then
        start_web_config_server
    else
        run_configuration_wizard
    fi
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
    if [[ "$plugin" == "webinstaller" && "$INSTALLER_FRONTEND" != "web" ]]; then
        continue
    fi
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
    default_state="OFF"
    if [[ "$INSTALLER_FRONTEND" == "web" && "$plugin" == "webinstaller" ]]; then
        default_state="ON"
    fi
    OPTIONS+=("$plugin" "$category" "$default_state")
done

if [[ "$NONINTERACTIVE" -eq 1 ]]; then
    SELECTED_SERVICES=("${AVAILABLE_PLUGINS[@]}")
elif [[ "$INSTALLER_FRONTEND" == "web" ]]; then
    start_web_selection_server
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

if [[ "$INSTALLER_FRONTEND" == "web" ]]; then
    init_web_progress
fi

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

if [[ "$INSTALLER_FRONTEND" != "web" ]]; then
    review_gate \
    "Install Services" \
    "Proceed with installation?" || exit 0
fi

########################################
# Port conflict check
########################################

INSTALLER_FRONTEND="$INSTALLER_FRONTEND" bash "$SCRIPT_DIR/port-check.sh" "${SELECTED_SERVICES[@]}"

########################################
# Generate docker compose
########################################

TMP_COMPOSE="$(mktemp -p "$STACK_DIR" -t docker-compose.XXXXXX)"
trap 'rm -f "$TMP_COMPOSE"; cleanup_web_session' EXIT
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
web_progress_set_phase "installing" "Installing selected plugins"
web_progress_set_service "Stage: Plugin Install" "in_progress" "Installing plugins"

for SERVICE in "${SELECTED_SERVICES[@]}"
do

    web_progress_set_service "$SERVICE" "in_progress" "Installing plugin"
    log "Installing $SERVICE"

    PLUGIN_FILE=$(get_plugin_path "$SERVICE")
    if ! validate_plugin_file "$PLUGIN_FILE"; then
        web_progress_set_service "$SERVICE" "failed" "Plugin validation failed"
        web_progress_set_phase "failed" "Installation failed on $SERVICE"
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$PLUGIN_FILE"

    if ! install_service; then
        web_progress_set_service "$SERVICE" "failed" "Plugin installation failed"
        web_progress_set_phase "failed" "Installation failed on $SERVICE"
        exit 1
    fi

    web_progress_set_service "$SERVICE" "done" "Installed"

done

web_progress_set_service "Stage: Plugin Install" "done" "All plugins installed"
web_progress_set_phase "installing" "Validating generated compose file"
web_progress_set_service "Stage: Compose Validate" "in_progress" "Validating compose configuration"

# Validate the generated compose file
if ! docker compose -f "$TMP_COMPOSE" config >/dev/null 2>&1; then
    error "Generated invalid docker-compose.yml"
    web_progress_set_service "Stage: Compose Validate" "failed" "Compose validation failed"
    web_progress_set_phase "failed" "Installation failed during compose validation"
    exit 1
fi

web_progress_set_service "Stage: Compose Validate" "done" "Compose file is valid"

mv "$TMP_COMPOSE" "$COMPOSE_FILE"

########################################
# Pull container images
########################################

progress_msg "Pulling container images"
web_progress_set_phase "installing" "Pulling container images"
web_progress_set_service "Stage: Pull Images" "in_progress" "Pulling required images"

if ! images="$(docker compose -f "$COMPOSE_FILE" config --format json 2>/dev/null | jq -r '.services[]?.image // empty')"; then
    images=""
fi

if [[ -z "$images" ]]; then
    images="$(docker compose -f "$COMPOSE_FILE" config 2>/dev/null | awk '/^[[:space:]]*image:/ {print $2}')"
fi

if [[ -z "$images" ]]; then
    error "Failed to get image list from compose file"
    web_progress_set_service "Stage: Pull Images" "failed" "Could not resolve image list"
    web_progress_set_phase "failed" "Installation failed while preparing image pulls"
    exit 1
fi

while IFS= read -r img; do
    [[ -n "$img" ]] && {
        log "Pulling $img"
        web_progress_set_service "Stage: Pull Images" "in_progress" "Pulling $img"
        if ! docker pull "$img"; then
            error "Failed to pull image: $img"
            web_progress_set_service "Stage: Pull Images" "failed" "Failed to pull $img"
            web_progress_set_phase "failed" "Installation failed while pulling images"
            exit 1
        fi
    }
done <<< "$images"

web_progress_set_service "Stage: Pull Images" "done" "All images pulled"

########################################
# Start containers
########################################

progress_msg "Starting containers"
web_progress_set_phase "installing" "Starting containers"
web_progress_set_service "Stage: Start Containers" "in_progress" "Starting docker compose stack"

if ! compose_up; then
    web_progress_set_service "Stage: Start Containers" "failed" "Failed to start containers"
    web_progress_set_phase "failed" "Installation failed while starting containers"
    exit 1
fi

web_progress_set_service "Stage: Start Containers" "done" "Containers started"

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
web_progress_set_phase "installing" "Running post-install tasks"
web_progress_set_service "Stage: Post Install" "in_progress" "Post-install tasks running in background"

bash "$SCRIPT_DIR/post-install.sh" \
>> "$STACK_DIR/logs/post-install.log" 2>&1 &

web_progress_set_service "Stage: Post Install" "done" "Post-install launched"

########################################
# Completion
########################################

INSTALLED_ENTRIES=()

echo ""
echo "================================"
echo "Installation Complete"
echo "================================"
echo ""

if ! show_installed_services; then
    IP=$(hostname -I | awk '{print $1}')
    echo "Homepage:"
    echo "http://$IP:3001"
    echo ""
    echo "Grafana:"
    echo "http://$IP:3000"
fi

echo ""
echo "Logs:"
echo "tail -f $STACK_DIR/logs/post-install.log"

echo ""

web_progress_set_phase "completed" "Installation completed successfully"
