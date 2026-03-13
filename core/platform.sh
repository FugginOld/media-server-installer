#!/usr/bin/env bash

########################################
# Platform Detection
########################################

PLATFORM_ID=""
PLATFORM_FAMILY=""
PACKAGE_MANAGER=""
NAS_PLATFORM="none"

########################################
# Require Root
########################################

require_root() {

if [ "$EUID" -ne 0 ]; then
echo "This installer must be run as root."
exit 1
fi

}

########################################
# Detect Linux Distribution
########################################

detect_platform() {

echo "Detecting operating system..."

if [ -f /etc/os-release ]; then
. /etc/os-release
PLATFORM_ID="${ID,,}"
else
PLATFORM_ID="unknown"
fi

########################################
# Detect NAS platforms
########################################

if [ -f /etc/unraid-version ]; then
NAS_PLATFORM="unraid"
fi

case "$PLATFORM_ID" in

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

########################################
# Debian family
########################################

debian|ubuntu|devuan|linuxmint|pop|elementary)
PLATFORM_FAMILY="debian"
PACKAGE_MANAGER="apt"
;;

########################################
# RedHat family
########################################

fedora|rhel|centos|rocky|almalinux)
PLATFORM_FAMILY="redhat"

if command -v dnf >/dev/null 2>&1; then
PACKAGE_MANAGER="dnf"
else
PACKAGE_MANAGER="yum"
fi
;;

########################################
# Arch family
########################################

arch|manjaro|endeavouros)
PLATFORM_FAMILY="arch"
PACKAGE_MANAGER="pacman"
;;

########################################
# SUSE family
########################################

opensuse*|sles)
PLATFORM_FAMILY="suse"
PACKAGE_MANAGER="zypper"
;;

########################################
# Alpine
########################################

alpine)
PLATFORM_FAMILY="alpine"
PACKAGE_MANAGER="apk"
;;

########################################
# Unknown
########################################

*)
PLATFORM_FAMILY="unknown"
PACKAGE_MANAGER="unknown"
;;

esac

########################################
# Output detected platform
########################################

echo "Detected OS: $PLATFORM_ID"
echo "Platform family: $PLATFORM_FAMILY"
echo "Package manager: $PACKAGE_MANAGER"

if [ "$NAS_PLATFORM" != "none" ]; then
echo "Detected NAS platform: $NAS_PLATFORM"
fi

########################################
# Validate platform
########################################

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
# Export environment
########################################

export PLATFORM_ID
export PLATFORM_FAMILY
export PACKAGE_MANAGER
export NAS_PLATFORM

export -f require_root
export -f detect_platform
export -f pkg_update
export -f pkg_install
