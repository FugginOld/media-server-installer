#!/usr/bin/env bash

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"


########################################
#Load environment
########################################

# Prevent double-loading
if [ -n "${MEDIA_STACK_ENV_LOADED:-}" ]; then
return
fi
export MEDIA_STACK_ENV_LOADED=1

########################################
#Stack directory
########################################

STACK_DIR="/opt/media-stack"

########################################
#Core directories
########################################

CONFIG_DIR="$STACK_DIR/config"
LOG_DIR="$STACK_DIR/logs"
BACKUP_DIR="$STACK_DIR/backups"

########################################
#Plugin architecture
########################################

PLUGIN_DIR="$INSTALL_DIR/plugins"

########################################
#Registry files
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"
PORT_REGISTRY="$STACK_DIR/ports.json"

########################################
#Default media directories
########################################

MEDIA_PATH="${MEDIA_PATH:-/media}"
MOVIES_PATH="${MOVIES_PATH:-/media/movies}"
TV_PATH="${TV_PATH:-/media/tv}"
DOWNLOADS_PATH="${DOWNLOADS_PATH:-/downloads}"

########################################
#Load saved environment variables
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
# shellcheck disable=SC1090
source "$STACK_DIR/stack.env"
fi

########################################
#Ensure base directories exist
########################################

mkdir -p "$STACK_DIR" "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"

########################################
#Ensure registry files exist
########################################

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo '{"services":[]}' > "$SERVICE_REGISTRY"
fi

if [ ! -f "$PORT_REGISTRY" ]; then
echo '{}' > "$PORT_REGISTRY"
fi

########################################
#Default container permissions
########################################

PUID=${PUID:-$(id -u)}
PGID=${PGID:-$(id -g)}
TIMEZONE=${TIMEZONE:-UTC}

########################################
#Export variables
########################################

export INSTALL_DIR
export STACK_DIR
export CONFIG_DIR
export LOG_DIR
export BACKUP_DIR
export PLUGIN_DIR

export SERVICE_REGISTRY
export PORT_REGISTRY

export MEDIA_PATH
export MOVIES_PATH
export TV_PATH
export DOWNLOADS_PATH

export PUID
export PGID
export TIMEZONE