#!/usr/bin/env bash
set -euo pipefail

########################################
# Media Stack Remote Installer
########################################

INSTALL_DIR="${INSTALL_DIR:-/opt/media-server-installer}"
REPO_URL="https://github.com/FugginOld/media-server-installer"

echo ""
echo "================================"
echo "Media Stack Installer"
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
# Detect package manager
########################################

detect_pkg_manager() {

if command -v apt >/dev/null 2>&1; then
PKG_UPDATE="apt update"
PKG_INSTALL="apt install -y"

elif command -v dnf >/dev/null 2>&1; then
PKG_UPDATE="dnf makecache"
PKG_INSTALL="dnf install -y"

elif command -v yum >/dev/null 2>&1; then
PKG_UPDATE="yum makecache"
PKG_INSTALL="yum install -y"

elif command -v pacman >/dev/null 2>&1; then
PKG_UPDATE="pacman -Sy"
PKG_INSTALL="pacman -S --noconfirm"

elif command -v zypper >/dev/null 2>&1; then
PKG_UPDATE="zypper refresh"
PKG_INSTALL="zypper install -y"

elif command -v apk >/dev/null 2>&1; then
PKG_UPDATE="apk update"
PKG_INSTALL="apk add"

else
echo "Unsupported package manager."
exit 1
fi

}

detect_pkg_manager

########################################
# Ensure required tools
########################################

ensure_dependency() {

CMD="$1"
PKG="$2"

if ! command -v "$CMD" >/dev/null 2>&1; then
echo "$CMD not found. Installing..."
$PKG_UPDATE
$PKG_INSTALL "$PKG"
fi

}

ensure_dependency git git
ensure_dependency curl curl
ensure_dependency tar tar

########################################
# Download or update installer
########################################

echo ""
echo "Preparing Media Stack Installer..."
echo ""

if [ -d "$INSTALL_DIR/.git" ]; then

echo "Existing installation detected."
echo "Updating installer..."

cd "$INSTALL_DIR"
git pull --ff-only

else

echo "Cloning installer repository..."

git clone "$REPO_URL" "$INSTALL_DIR"

fi

########################################
# Ensure shell scripts executable
########################################

find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

########################################
# Install CLI command
########################################

CLI_SRC="$INSTALL_DIR/bin/media-stack"
CLI_DST="/usr/local/bin/media-stack"

if [ -f "$CLI_SRC" ]; then

ln -sf "$CLI_SRC" "$CLI_DST"
chmod +x "$CLI_SRC"

echo ""
echo "Media Stack CLI installed."
echo "Command available as: media-stack"
echo ""

else

echo "Warning: media-stack CLI not found at $CLI_SRC"

fi

########################################
# Launch installer
########################################

cd "$INSTALL_DIR"

echo ""
echo "Launching installer..."
echo ""

bash installer.sh
