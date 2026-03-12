#!/usr/bin/env bash

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Determine PUID / PGID
########################################

detect_user_ids() {

if [ -z "$PUID" ]; then
PUID=$(id -u)
fi

if [ -z "$PGID" ]; then
PGID=$(id -g)
fi

echo "Using PUID=$PUID"
echo "Using PGID=$PGID"

}

########################################
# Fix directory permissions
########################################

fix_media_permissions() {

echo "Fixing directory permissions..."

DIRS=(
"$MEDIA_PATH"
"$MOVIES_PATH"
"$TV_PATH"
"$DOWNLOADS_PATH"
"$CONFIG_DIR"
)

for DIR in "${DIRS[@]}"
do

if [ -n "$DIR" ] && [ -d "$DIR" ]; then
echo "Fixing permissions: $DIR"
chown -R "$PUID:$PGID" "$DIR"
chmod -R 775 "$DIR"
fi

done

}

########################################
# NAS specific adjustments
########################################

apply_nas_permissions() {

case "$NAS_PLATFORM" in

unraid)

echo "Applying Unraid permission fixes..."

chmod -R 777 "$MEDIA_PATH"
chmod -R 777 "$DOWNLOADS_PATH"

;;

truenas)

echo "Applying TrueNAS container permissions..."

chmod -R 775 "$MEDIA_PATH"
chmod -R 775 "$DOWNLOADS_PATH"

;;

openmediavault)

echo "Applying OMV docker permissions..."

chown -R "$PUID:$PGID" "$MEDIA_PATH"

;;

casaos)

echo "Applying CasaOS docker permissions..."

chmod -R 775 "$MEDIA_PATH"

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

fix_media_permissions

apply_nas_permissions

}

export -f setup_permissions
