#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
#Load environment (if available)
########################################

if [ -n "${INSTALL_DIR:-}" ] && [ -f "$INSTALL_DIR/core/env.sh" ]; then
source "$INSTALL_DIR/core/env.sh"
fi

########################################
#Media Stack Preflight Checks
########################################

echo ""
echo "================================"
echo "Media Stack Preflight Checks"
echo "================================"
echo ""

########################################
#Ensure running as root
########################################

if [ "$EUID" -ne 0 ]; then
echo "Installer must be run as root."
exit 1
fi

echo "Running as root: OK"

########################################
#Detect operating system
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
#CPU architecture
########################################

ARCH=$(uname -m)

case "$ARCH" in
x86_64|amd64|aarch64|arm64)
echo "Supported architecture: $ARCH"
;;
*)
echo "Unsupported architecture: $ARCH"
exit 1
;;
esac

########################################
#Internet connectivity
########################################

echo "Checking internet connectivity..."

if curl -fsSL https://github.com >/dev/null 2>&1; then
echo "Internet connectivity: OK"
else
echo "Internet connection failed."
exit 1
fi

########################################
#Required commands
########################################

REQUIRED_CMDS=(
curl
git
jq
pciutils
)

MISSING=()

for CMD in "${REQUIRED_CMDS[@]}"
do

if command -v "$CMD" >/dev/null 2>&1; then
echo "$CMD installed"
else
echo "$CMD missing"
MISSING+=("$CMD")
fi

done

########################################
#Install missing dependencies
########################################

if [ "${#MISSING[@]}" -gt 0 ]; then

echo ""
echo "Installing missing dependencies..."
echo ""

apt update

for PKG in "${MISSING[@]}"
do
apt install -y "$PKG"
done

fi

########################################
#Docker check
########################################

if command -v docker >/dev/null 2>&1; then
echo "Docker detected"

if docker compose version >/dev/null 2>&1; then
echo "Docker Compose detected"
else
echo "Docker Compose missing (will be installed later)"
fi

else
echo "Docker not installed (will be installed later)"
fi

########################################
#Disk space check
########################################

FREE_KB=$(df / | awk 'NR==2 {print $4}')
FREE_GB=$((FREE_KB / 1024 / 1024))

if [ "$FREE_KB" -lt 1048576 ]; then
echo "Less than 1GB free disk space."
exit 1
fi

echo "Disk space available: ${FREE_GB}GB"

echo ""
echo "Preflight checks passed."
echo ""