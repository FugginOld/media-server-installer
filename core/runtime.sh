#!/usr/bin/env bash

########################################
# Prevent double loading
########################################

if [ -n "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
return
fi
export MEDIA_STACK_RUNTIME_LOADED=1

########################################
# Resolve installer directory
########################################

# If INSTALL_DIR already set and valid
if [ -n "${INSTALL_DIR:-}" ] && [ -d "$INSTALL_DIR" ]; then
:

# Standard system install location
elif [ -d "/opt/media-server-installer" ]; then
INSTALL_DIR="/opt/media-server-installer"

# Fallback to script location
else
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

export INSTALL_DIR

########################################
# Verify installer directory
########################################

if [ ! -d "$INSTALL_DIR" ]; then
echo "Failed to resolve installer directory."
exit 1
fi

########################################
# Define common runtime paths
########################################

export CORE_DIR="$INSTALL_DIR/core"
export SCRIPT_DIR="$INSTALL_DIR/scripts"
export PLUGIN_DIR="$INSTALL_DIR/plugins"

########################################
# Load environment configuration
########################################

ENV_FILE="$INSTALL_DIR/core/env.sh"

if [ -f "$ENV_FILE" ]; then
source "$ENV_FILE"
else
echo "Warning: env.sh not found at $ENV_FILE"
fi
