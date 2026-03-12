#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Media Stack Remote Installer
#
# Downloads or updates the installer
# and launches the setup process.
########################################

echo "================================"
echo ""

########################################
# Ensure running as root
########################################

if [ "$EUID" -ne 0 ]; then
echo "Please run installer as root."
echo "Example:"
echo "sudo bash install.sh"
exit 1
fi

########################################
# Ensure git is installed
########################################

if ! command -v git >/dev/null 2>&1; then
echo "Git not found. Installing..."

apt update
apt install -y git
fi

########################################
# Download or update installer
########################################

echo "Downloading Media Stack Installer..."

if [ -d "$INSTALL_DIR" ]; then

echo "Existing installation detected."
echo "Updating installer..."

cd "$INSTALL_DIR"
git pull

else

git clone https://github.com/FugginOld/media-server-installer "$INSTALL_DIR"

fi

########################################
# Ensure scripts are executable
########################################

chmod -R +x "$INSTALL_DIR"

########################################
# Install CLI command
########################################

ln -sf "$INSTALL_DIR/scripts/media-stack" /usr/local/bin/media-stack

########################################
# Launch installer
########################################

cd "$INSTALL_DIR"

echo ""
echo "Launching installer..."
echo ""

bash installer.sh
