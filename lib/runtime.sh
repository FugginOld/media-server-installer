#!/usr/bin/env bash

########################################
# Prevent double loading
########################################

if [ -n "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
    return
fi
export MEDIA_STACK_RUNTIME_LOADED=1

########################################
# Resolve INSTALL_DIR
########################################

if [ -n "${INSTALL_DIR:-}" ] && [ -d "$INSTALL_DIR" ]; then
    :
else
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

export INSTALL_DIR

########################################
# Standard project directories
########################################

CORE_DIR="$INSTALL_DIR/core"
LIB_DIR="$INSTALL_DIR/lib"
SCRIPT_DIR="$INSTALL_DIR/scripts"
PLUGIN_DIR="$INSTALL_DIR/plugins"
TEMPLATE_DIR="$INSTALL_DIR/templates"

export CORE_DIR
export LIB_DIR
export SCRIPT_DIR
export PLUGIN_DIR
export TEMPLATE_DIR

########################################
# Verify directories exist
########################################

if [ ! -d "$CORE_DIR" ]; then
    echo "Runtime error: core directory missing"
    exit 1
fi

########################################
# Detect host IP
########################################

detect_host_ip() {

    HOST_IP=""

    if command -v ip >/dev/null 2>&1; then
        HOST_IP="$(ip route get 1 | awk '{print $7; exit}')"
    fi

    if [ -z "$HOST_IP" ]; then
        HOST_IP="$(hostname -I | awk '{print $1}')"
    fi

    if [ -z "$HOST_IP" ]; then
        HOST_IP="127.0.0.1"
    fi
}

detect_host_ip
export HOST_IP

########################################
# Logging helper
########################################

log() {
    echo "[media-stack] $*"
}

export -f log