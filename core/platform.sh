#!/usr/bin/env bash

########################################
# Media Stack Platform Detection
########################################

PLATFORM_ID=""
PLATFORM_FAMILY=""
PACKAGE_MANAGER=""
NAS_PLATFORM="none"

########################################
# Detect Linux Distribution
########################################

detect_platform() {

echo "Detecting operating system..."

if [ -f /etc/os-release ]; then
    source /etc/os-release
    PLATFORM_ID="$ID"
else
    PLATFORM_ID="unknown"
fi

########################################
# Detect NAS Platforms
########################################

if [ -f /etc/unraid-version ]; then
    NAS_PLATFORM="unraid"
fi

if grep -qi "truenas" /etc/os-release 2>/dev/null; then
    NAS_PLATFORM="truenas"
fi

if grep -qi "openmediavault" /etc/os-release 2>/dev/null; then
    NAS_PLATFORM="openmediavault"
fi

if grep -qi "casaos" /etc/os-release 2>/dev/null; then
    NAS_PLATFORM="casaos"
fi

########################################
# Determine platform family
########################################

case "$PLATFORM_ID" in

    debian|ubuntu|devuan|linuxmint|pop)
        PLATFORM_FAMILY="debian"
        PACKAGE_MANAGER="apt"
    ;;

    fedora|rhel|centos|rocky|almalinux)
        PLATFORM_FAMILY="redhat"
        PACKAGE_MANAGER="dnf"
    ;;

    arch|manjaro|endeavouros)
        PLATFORM_FAMILY="arch"
        PACKAGE_MANAGER="pacman"
    ;;

    opensuse*|sles)
        PLATFORM_FAMILY="suse"
        PACKAGE_MANAGER="zypper"
    ;;

    alpine)
        PLATFORM_FAMILY="alpine"
        PACKAGE_MANAGER="apk"
    ;;

    *)
        PLATFORM_FAMILY="unknown"
        PACKAGE_MANAGER="unknown"
    ;;

esac

echo "Detected OS: $PLATFORM_ID"
echo "Platform family: $PLATFORM_FAMILY"

if [ "$NAS_PLATFORM" != "none" ]; then
    echo "Detected NAS platform: $NAS_PLATFORM"
fi

}

########################################
# Package Manager Abstraction
########################################

pkg_update() {

case "$PACKAGE_MANAGER" in

apt) apt update ;;
dnf) dnf makecache ;;
pacman) pacman -Sy --noconfirm ;;
zypper) zypper refresh ;;
apk) apk update ;;

*)
echo "Unsupported package manager"
exit 1
;;

esac

}

pkg_install() {

case "$PACKAGE_MANAGER" in

apt) apt install -y "$@" ;;
dnf) dnf install -y "$@" ;;
pacman) pacman -S --noconfirm "$@" ;;
zypper) zypper install -y "$@" ;;
apk) apk add "$@" ;;

*)
echo "Unsupported package manager"
exit 1
;;

esac

}

export PLATFORM_ID
export PLATFORM_FAMILY
export PACKAGE_MANAGER
export NAS_PLATFORM