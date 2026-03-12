#!/usr/bin/env bash

########################################
#Prevent double loading
########################################

if [ -n "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
return
fi
export MEDIA_STACK_RUNTIME_LOADED=1

########################################
#Resolve installer directory
########################################

if [ -n "${INSTALL_DIR:-}" ] && [ -d "$INSTALL_DIR" ]; then
:
else

# Try common install location
if [ -d "/opt/media-server-installer" ]; then
INSTALL_DIR="/opt/media-server-installer"

# Otherwise resolve relative to runtime.sh
else
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

fi

export INSTALL_DIR

########################################
#Load environment
########################################

if [ -f "$INSTALL_DIR/core/env.sh" ]; then
# shellcheck disable=SC1090
source "$INSTALL_DIR/core/env.sh"
else
echo "Environment file missing: $INSTALL_DIR/core/env.sh" >&2
exit 1
fi
