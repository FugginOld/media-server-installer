#!/usr/bin/env bash

########################################
# Media Stack Preflight Checks
#
# Ensures the system has the required
# dependencies before running installer
########################################

echo ""
echo "================================"
echo " Media Stack Preflight Checks"
echo "================================"
echo ""

########################################
# Ensure script is run as root
########################################

if [ "$EUID" -ne 0 ]; then
echo "Installer must be run as root."
exit 1
fi

echo "Running as root: OK"

########################################
# Detect OS
########################################

if [ -f /etc/os-release ]; then
. /etc/os-release
else
echo "Cannot detect operating system."
exit 1
fi

case "$ID" in
debian|devuan|ubuntu)
echo "Supported OS detected: $ID"
;;
*)
echo "Unsupported OS: $ID"
exit 1
;;
esac

########################################
# Internet connectivity
########################################

echo "Checking internet connectivity..."

if ping -c 1 github.com >/dev/null 2>&1; then
echo "Internet connectivity: OK"
else
echo "Internet connection failed."
exit 1
fi

########################################
# Required commands
########################################

REQUIRED_CMDS=(
curl
git
jq
pciutils
)

for CMD in "${REQUIRED_CMDS[@]}"
do

if command -v "$CMD" >/dev/null 2>&1; then

echo "$CMD installed"

else

echo "$CMD missing — installing..."

apt update
apt install -y "$CMD"

fi

done

########################################
# Disk space check
########################################

FREE_SPACE=$(df / | awk 'NR==2 {print $4}')

if [ "$FREE_SPACE" -lt 1048576 ]; then
echo "Less than 1GB free disk space."
exit 1
fi

echo "Disk space check: OK"

echo ""
echo "Preflight checks passed."
echo ""