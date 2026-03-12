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

if [ -d "/opt/media-server-installer" ]; then
INSTALL_DIR="/opt/media-server-installer"
else
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

fi

export INSTALL_DIR

########################################
#Load environment
########################################

source "$INSTALL_DIR/core/env.sh"
