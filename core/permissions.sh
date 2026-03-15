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
# Permissions Management
########################################

########################################
# Determine PUID / PGID
########################################

detect_user_ids() {

if [ -z "${PUID:-}" ]; then
PUID=$(id -u)
fi

if [ -z "${PGID:-}" ]; then
PGID=$(id -g)
fi

export PUID
export PGID

echo "Using PUID=$PUID"
echo "Using PGID=$PGID"

}

########################################
# Resolve directory variables
########################################

resolve_directories() {

MEDIA_ROOT="${MEDIA_DIR:-${MEDIA_PATH:-/media}}"
MOVIES_ROOT="${MOVIES_DIR:-${MOVIES_PATH:-/media/movies}}"
TV_ROOT="${TV_DIR:-${TV_PATH:-/media/tv}}"
DOWNLOADS_ROOT="${DOWNLOADS_DIR:-${DOWNLOADS_PATH:-/downloads}}"

}

########################################
# Fix directory permissions
########################################

fix_media_permissions() {

echo "Fixing directory permissions..."

DIRS=(
"$MEDIA_ROOT"
"$MOVIES_ROOT"
"$TV_ROOT"
"$DOWNLOADS_ROOT"
"$CONFIG_DIR"
)

for DIR in "${DIRS[@]}"
do

if [ -z "$DIR" ]; then
continue
fi

if [ "$DIR" = "/" ]; then
continue
fi

if [ ! -d "$DIR" ]; then
mkdir -p "$DIR"
fi

echo "Fixing permissions: $DIR"

chown -R "$PUID:$PGID" "$DIR" 2>/dev/null || true
chmod -R 775 "$DIR" 2>/dev/null || true

done

}

########################################
# NAS specific adjustments
########################################

apply_nas_permissions() {

case "$NAS_PLATFORM" in

unraid)

echo "Applying Unraid permission fixes..."

chmod -R 777 "$MEDIA_ROOT" 2>/dev/null || true
chmod -R 777 "$DOWNLOADS_ROOT" 2>/dev/null || true

;;

truenas)

echo "Applying TrueNAS container permissions..."

chmod -R 775 "$MEDIA_ROOT" 2>/dev/null || true
chmod -R 775 "$DOWNLOADS_ROOT" 2>/dev/null || true

;;

openmediavault)

echo "Applying OMV docker permissions..."

chown -R "$PUID:$PGID" "$MEDIA_ROOT" 2>/dev/null || true

;;

casaos)

echo "Applying CasaOS docker permissions..."

chmod -R 775 "$MEDIA_ROOT" 2>/dev/null || true

;;

*)

echo "No NAS-specific permission rules applied."

;;

esac

}

########################################
# Main permission setup
########################################

setup_permissions() {

detect_user_ids
resolve_directories
fix_media_permissions
apply_nas_permissions

}

########################################
# Export functions
########################################

export -f detect_user_ids
export -f resolve_directories
export -f fix_media_permissions
export -f apply_nas_permissions
export -f setup_permissions