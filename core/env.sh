#!/usr/bin/env bash

########################################
# Media Stack Environment Loader
########################################

########################################
# Determine installer directory
########################################

if [ -z "$INSTALL_DIR" ]; then
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

########################################
# Stack directory
########################################

STACK_DIR="/opt/media-stack"

########################################
# Configuration directory
########################################

CONFIG_DIR="$STACK_DIR/config"

########################################
# Registry files
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"
PORT_REGISTRY="$STACK_DIR/ports.json"

########################################
# Default media directories
########################################

MEDIA_PATH="${MEDIA_PATH:-/media}"
MOVIES_PATH="${MOVIES_PATH:-/media/movies}"
TV_PATH="${TV_PATH:-/media/tv}"
DOWNLOADS_PATH="${DOWNLOADS_PATH:-/downloads}"

########################################
# Load saved environment variables
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Ensure base directories exist
########################################

mkdir -p "$STACK_DIR"
mkdir -p "$CONFIG_DIR"

########################################
# Export variables
########################################

export INSTALL_DIR
export STACK_DIR
export CONFIG_DIR
export SERVICE_REGISTRY
export PORT_REGISTRY

export MEDIA_PATH
export MOVIES_PATH
export TV_PATH
export DOWNLOADS_PATH