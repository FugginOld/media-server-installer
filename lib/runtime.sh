#!/usr/bin/env bash
set -euo pipefail

########################################
# Prevent double loading
########################################

if [[ -n "${MEDIA_STACK_RUNTIME_LOADED:-}" ]]; then
    return
fi
export MEDIA_STACK_RUNTIME_LOADED=1

########################################
# Resolve INSTALL_DIR
########################################

if [[ -z "${INSTALL_DIR:-}" ]]; then
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    INSTALL_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
fi

export INSTALL_DIR

########################################
# Core project directories
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
# Stack directory
########################################

STACK_DIR="${STACK_DIR:-/opt/media-stack}"
export STACK_DIR

########################################
# Validate directory structure
########################################

[[ -d "$CORE_DIR" ]] || { echo "Runtime error: core directory missing"; exit 1; }
[[ -d "$LIB_DIR" ]] || { echo "Runtime error: lib directory missing"; exit 1; }
[[ -d "$SCRIPT_DIR" ]] || { echo "Runtime error: scripts directory missing"; exit 1; }
[[ -d "$PLUGIN_DIR" ]] || { echo "Runtime error: plugins directory missing"; exit 1; }

########################################
# Logging functions
########################################

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

error() {
    echo "[ERROR] $*" >&2
}

die() {
    error "$*"
    exit 1
}

########################################
# Export logging functions
########################################

export -f log
export -f warn
export -f error
export -f die

########################################
# Detect host IP
########################################

detect_host_ip() {

HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

if [[ -z "$HOST_IP" ]]; then
    HOST_IP="127.0.0.1"
fi

export HOST_IP
}

detect_host_ip

########################################
# Runtime banner
########################################

echo ""
echo "Using PUID=${PUID:-unknown}"
echo "Using PGID=${PGID:-unknown}"
echo "Detected HOST_IP=$HOST_IP"
echo ""
