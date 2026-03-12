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
. /etc/os-release
PLATFORM_ID="$ID"
else
PLATFORM_ID="unknown"
fi

########################################
# Detect NAS platforms
########################################

if [ -f /etc/unraid-version ]; then
NAS_PLATFORM="unraid"
fi

case "$ID" in
truenas*)
NAS_PLATFORM="truenas"
;;
openmediavault)
NAS_PLATFORM="openmediavault"
;;
casaos)
NAS_PLATFORM="casaos"
;;
esac

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

if command -v dnf >/dev/null 2>&1; then
PACKAGE_MANAGER="dnf"
else
PACKAGE_MANAGER="yum"
fi
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

if [ "$PACKAGE_MANAGER" = "unknown" ]; then
echo "Unsupported Linux distribution."
exit 1
fi

}

########################################
# Package Manager Abstraction
########################################

pkg_update() {

case "$PACKAGE_MANAGER" in

apt)
apt update
;;

dnf)
dnf makecache
;;

yum)
yum makecache
;;

pacman)
pacman -Syu --noconfirm
;;

zypper)
zypper refresh
;;

apk)
apk update
;;

*)
echo "Unsupported package manager"
exit 1
;;

esac

}

pkg_install() {

case "$PACKAGE_MANAGER" in

apt)
apt install -y "$@"
;;

dnf)
dnf install -y "$@"
;;

yum)
yum install -y "$@"
;;

pacman)
pacman -S --noconfirm "$@"
;;

zypper)
zypper install -y "$@"
;;

apk)
apk add "$@"
;;

*)
echo "Unsupported package manager"
exit 1
;;

esac

}

########################################
# Export variables
########################################

export PLATFORM_ID
export PLATFORM_FAMILY
export PACKAGE_MANAGER
export NAS_PLATFORM
export -f detect_platform
export -f pkg_update
export -f pkg_install
