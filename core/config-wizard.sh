#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime if not already loaded
########################################

if [ -z "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"
source "$INSTALL_DIR/lib/runtime.sh"
fi

########################################
# Configuration Wizard
########################################

CONFIG_FILE="$STACK_DIR/stack.env"

########################################
# Load existing configuration
########################################

if [ -f "$CONFIG_FILE" ]; then
# shellcheck disable=SC1090
source "$CONFIG_FILE"
fi

########################################
# Validation functions
########################################

validate_uid() {
    local uid="$1"
    if ! [[ "$uid" =~ ^[0-9]+$ ]] || [[ "$uid" -lt 0 ]] || [[ "$uid" -gt 65535 ]]; then
        return 1
    fi
    return 0
}

get_validated_uid() {
    local prompt="$1" default="$2"
    local uid
    while true; do
        uid=$(whiptail \
            --title "Media Stack Configuration" \
            --inputbox "$prompt" \
            10 60 "$default" \
            3>&1 1>&2 2>&3)
        if validate_uid "$uid"; then
            echo "$uid"
            return 0
        fi
        whiptail --msgbox "Invalid UID. Must be between 0-65535" 10 40
    done
}

########################################
# Run configuration wizard
########################################

run_configuration_wizard() {

########################################
# Ensure stack directory exists
########################################

mkdir -p "$STACK_DIR"

########################################
# Detect defaults
########################################

DEFAULT_TZ="${TIMEZONE:-$(timedatectl show --property=Timezone --value 2>/dev/null)}"
DEFAULT_TZ="${DEFAULT_TZ:-UTC}"

DEFAULT_UID="${PUID:-$(id -u)}"
DEFAULT_GID="${PGID:-$(id -g)}"
DEFAULT_NET="${DOCKER_NETWORK:-media-network}"
DEFAULT_DIR_MODE="${DIR_MODE:-default}"

########################################
# Timezone prompt
########################################

TIMEZONE=$(whiptail \
--title "Media Stack Configuration" \
--inputbox "Timezone:" \
10 60 "$DEFAULT_TZ" \
3>&1 1>&2 2>&3)

########################################
# PUID prompt
########################################

PUID=$(get_validated_uid "Container User ID (PUID):" "$DEFAULT_UID")

########################################
# PGID prompt
########################################

PGID=$(get_validated_uid "Container Group ID (PGID):" "$DEFAULT_GID")

########################################
# Docker network prompt
########################################

DOCKER_NETWORK=$(whiptail \
--title "Media Stack Configuration" \
--inputbox "Docker Network Name:" \
10 60 "$DEFAULT_NET" \
3>&1 1>&2 2>&3)

########################################
# Directory layout selection
########################################

DIR_MODE=$(whiptail \
--title "Directory Layout" \
--menu "Select directory structure:" \
15 70 2 \
default "Follow OS/NAS default layout" \
trash "Use Trash Guides directory structure" \
3>&1 1>&2 2>&3)

########################################
# Save configuration
########################################

cat <<EOF > "$CONFIG_FILE"
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
DOCKER_NETWORK=$DOCKER_NETWORK
DIR_MODE=$DIR_MODE
EOF

echo ""
echo "Configuration saved:"
echo "$CONFIG_FILE"
echo ""

}

########################################
# Export function
########################################

export -f run_configuration_wizard