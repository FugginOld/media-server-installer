#!/usr/bin/env bash

echo ""
echo "================================"
echo " Running Preflight Checks"
echo "================================"
echo ""

########################################
# OS Check
########################################

if ! grep -Ei "debian|ubuntu|devuan" /etc/os-release > /dev/null; then
echo "Unsupported OS detected."
echo "Supported systems:"
echo "Debian / Ubuntu / Devuan"
exit 1
fi

echo "OS check passed."

########################################
# Internet Check
########################################

if ! ping -c1 github.com >/dev/null 2>&1; then
echo "Internet connectivity failed."
echo "Please verify network connection."
exit 1
fi

echo "Internet connectivity OK."

########################################
# Disk Space Check
########################################

FREE=$(df / | awk 'NR==2 {print $4}')

if [ "$FREE" -lt 2000000 ]; then
echo "Less than 2GB free disk space."
echo "Installation aborted."
exit 1
fi

echo "Disk space OK."

########################################
# Docker Check
########################################

if ! command -v docker >/dev/null 2>&1; then
echo "Docker not detected."
echo "Docker will be installed by the bootstrap installer."
else
echo "Docker detected."
fi

echo ""
echo "Preflight checks passed."
echo ""