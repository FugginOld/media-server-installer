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
SCRIPT_DIR="$INSTALL_DIR/scripts"
PLUGIN_DIR="$INSTALL_DIR/plugins"
TEMPLATE_DIR="$INSTALL_DIR/templates"

export CORE_DIR
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

if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Runtime error: scripts directory missing"
    exit 1
fi

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Runtime error: plugins directory missing"
    exit 1
fi

########################################
# Load environment
########################################

source "$CORE_DIR/env.sh"
