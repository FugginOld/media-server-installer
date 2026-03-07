#!/usr/bin/env bash

########################################
# Platform Detection
#
# Determines operating system,
# package manager, service manager,
# and runtime environment.
########################################

PLATFORM_OS="unknown"
PLATFORM_FAMILY="unknown"
PLATFORM_ENV="unknown"

PACKAGE_MANAGER="unknown"
SERVICE_MANAGER="unknown"

########################################
# Detect OS
########################################

detect_platform() {

echo ""
echo "Detecting platform..."
echo ""

########################################
# Load OS metadata
########################################

if [ -f /etc/os-release ]; then
. /etc/os-release
fi

########################################
# Debian
########################################

if echo "$ID" | grep -qi debian; then

PLATFORM_OS="debian"
PLATFORM_FAMILY="debian"
PACKAGE_MANAGER="apt"
SERVICE_MANAGER="systemd"

########################################
# Devuan
########################################

elif echo "$ID" | grep -qi devuan; then

PLATFORM_OS="devuan"
PLATFORM_FAMILY="debian"
PACKAGE_MANAGER="apt"
SERVICE_MANAGER="sysvinit"

########################################
# Ubuntu
########################################

elif echo "$ID" | grep -qi ubuntu; then

PLATFORM_OS="ubuntu"
PLATFORM_FAMILY="debian"
PACKAGE_MANAGER="apt"
SERVICE_MANAGER="systemd"

########################################
# Unraid
########################################

elif [ -f /etc/unraid-version ]; then

PLATFORM_OS="unraid"
PLATFORM_FAMILY="slackware"
PLATFORM_ENV="nas"
PACKAGE_MANAGER="none"
SERVICE_MANAGER="none"

########################################
# TrueNAS
########################################

elif echo "$NAME" | grep -qi truenas; then

PLATFORM_OS="truenas"
PLATFORM_FAMILY="freebsd"
PLATFORM_ENV="nas"
PACKAGE_MANAGER="none"
SERVICE_MANAGER="none"

########################################
# Generic Linux
########################################

else

PLATFORM_OS="$ID"
PLATFORM_FAMILY="linux"
PACKAGE_MANAGER="unknown"
SERVICE_MANAGER="unknown"

fi

########################################
# Detect runtime environment
########################################

detect_environment

########################################
# Display results
########################################

echo "OS: $PLATFORM_OS"
echo "Family: $PLATFORM_FAMILY"
echo "Environment: $PLATFORM_ENV"
echo "Package Manager: $PACKAGE_MANAGER"
echo "Service Manager: $SERVICE_MANAGER"

}

########################################
# Detect runtime environment
########################################

detect_environment() {

########################################
# Docker container
########################################

if grep -qa docker /proc/1/cgroup; then

PLATFORM_ENV="docker"

########################################
# LXC container
########################################

elif grep -qa lxc /proc/1/cgroup; then

PLATFORM_ENV="lxc"

########################################
# VM detection
########################################

elif command -v systemd-detect-virt >/dev/null 2>&1; then

VIRT=$(systemd-detect-virt)

if [ "$VIRT" != "none" ]; then
PLATFORM_ENV="vm"
else
PLATFORM_ENV="baremetal"
fi

########################################
# Fallback
########################################

else

PLATFORM_ENV="baremetal"

fi

}