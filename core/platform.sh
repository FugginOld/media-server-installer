#!/usr/bin/env bash

########################################
# Platform detection
########################################

HOST_PLATFORM="baremetal"

detect_platform() {

echo "Detecting host platform..."

if [ -f /etc/unraid-version ]; then

    HOST_PLATFORM="unraid"

elif grep -qi truenas /etc/os-release 2>/dev/null; then

    HOST_PLATFORM="truenas"

elif grep -qi openmediavault /etc/os-release 2>/dev/null; then

    HOST_PLATFORM="openmediavault"

elif grep -qi proxmox /etc/os-release 2>/dev/null; then

    HOST_PLATFORM="proxmox"

elif grep -qi synology /etc/os-release 2>/dev/null; then

    HOST_PLATFORM="synology"

else

    HOST_PLATFORM="baremetal"

fi

echo "Detected platform: $HOST_PLATFORM"

}

########################################
# Storage path configuration
########################################

configure_storage_paths() {

case "$HOST_PLATFORM" in

baremetal)

    MEDIA_PATH="/mnt/media"
    DOWNLOAD_PATH="/mnt/downloads"
    ;;

proxmox)

    MEDIA_PATH="/mnt/media"
    DOWNLOAD_PATH="/mnt/downloads"
    ;;

unraid)

    MEDIA_PATH="/mnt/user/media"
    DOWNLOAD_PATH="/mnt/user/downloads"
    ;;

truenas)

    MEDIA_PATH="/mnt/tank/media"
    DOWNLOAD_PATH="/mnt/tank/downloads"
    ;;

openmediavault)

    MEDIA_PATH="/srv/dev-disk-by-label-media"
    DOWNLOAD_PATH="/srv/dev-disk-by-label-downloads"
    ;;

synology)

    MEDIA_PATH="/volume1/media"
    DOWNLOAD_PATH="/volume1/downloads"
    ;;

*)

    MEDIA_PATH="/mnt/media"
    DOWNLOAD_PATH="/mnt/downloads"
    ;;

esac

echo "Media path: $MEDIA_PATH"
echo "Download path: $DOWNLOAD_PATH"

}