#!/usr/bin/env bash

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

PUID=$(whiptail \
--title "Media Stack Configuration" \
--inputbox "Container User ID (PUID):" \
10 60 "$DEFAULT_UID" \
3>&1 1>&2 2>&3)

########################################
# PGID prompt
########################################

PGID=$(whiptail \
--title "Media Stack Configuration" \
--inputbox "Container Group ID (PGID):" \
10 60 "$DEFAULT_GID" \
3>&1 1>&2 2>&3)

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