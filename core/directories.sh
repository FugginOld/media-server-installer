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
# Directory Mode
########################################

# Options expected from config wizard
# default → OS/NAS native layout
# trash   → Trash Guides layout

DIR_MODE="${DIR_MODE:-default}"

########################################
# Base stack directory
########################################

STACK_DIR="${STACK_DIR:-/opt/media-stack}"

CONFIG_DIR="$STACK_DIR/config"
LOG_DIR="$STACK_DIR/logs"
BACKUP_DIR="$STACK_DIR/backups"

########################################
# Apply Directory Layout
########################################

apply_directory_layout() {

echo ""
echo "Configuring directory layout..."

case "$DIR_MODE" in

########################################
# OS / NAS Default Layout
########################################

default)

MEDIA_DIR="${MEDIA_PATH:-/media}"
MOVIES_DIR="${MOVIES_PATH:-$MEDIA_DIR/movies}"
TV_DIR="${TV_PATH:-$MEDIA_DIR/tv}"
DOWNLOADS_DIR="${DOWNLOADS_PATH:-/downloads}"

echo "Using OS/NAS default directory structure."

;;

########################################
# Trash Guides Layout
########################################

trash)

MEDIA_DIR="/data/media"
DOWNLOADS_DIR="/data/downloads"

MOVIES_DIR="$MEDIA_DIR/movies"
TV_DIR="$MEDIA_DIR/tv"

echo "Using Trash Guides directory structure."

;;

########################################
# Fallback
########################################

*)

echo "Unknown directory mode: $DIR_MODE"
echo "Falling back to default layout."

MEDIA_DIR="/media"
MOVIES_DIR="/media/movies"
TV_DIR="/media/tv"
DOWNLOADS_DIR="/downloads"

;;

esac

########################################
# Compatibility exports
########################################

MEDIA_PATH="$MEDIA_DIR"
MOVIES_PATH="$MOVIES_DIR"
TV_PATH="$TV_DIR"
DOWNLOADS_PATH="$DOWNLOADS_DIR"

export MEDIA_DIR
export MOVIES_DIR
export TV_DIR
export DOWNLOADS_DIR

export MEDIA_PATH
export MOVIES_PATH
export TV_PATH
export DOWNLOADS_PATH

}

########################################
# Create directories
########################################

create_directories() {

mkdir -p "$STACK_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

mkdir -p "$MEDIA_DIR"
mkdir -p "$MOVIES_DIR"
mkdir -p "$TV_DIR"
mkdir -p "$DOWNLOADS_DIR"

}

########################################
# Display directory layout
########################################

show_directories() {

echo ""
echo "Directory Layout"
echo "----------------"
echo "Mode:        $DIR_MODE"
echo ""
echo "Stack:       $STACK_DIR"
echo "Config:      $CONFIG_DIR"
echo "Logs:        $LOG_DIR"
echo "Backups:     $BACKUP_DIR"
echo ""
echo "Media Root:  $MEDIA_DIR"
echo "Movies:      $MOVIES_DIR"
echo "TV:          $TV_DIR"
echo "Downloads:   $DOWNLOADS_DIR"
echo ""

}

########################################
# Export base variables
########################################

export STACK_DIR
export CONFIG_DIR
export LOG_DIR
export BACKUP_DIR
export DIR_MODE

########################################
# Export functions
########################################

export -f apply_directory_layout
export -f create_directories
export -f show_directories