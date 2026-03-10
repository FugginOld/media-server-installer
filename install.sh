#!/usr/bin/env bash

INSTALL_DIR="/opt/media-server-installer"
REPO="https://github.com/FugginOld/media-server-installer"
BRANCH="development"

echo "Downloading Media Stack Installer..."

if [ -d "$INSTALL_DIR" ]; then

echo "Existing installation detected."
echo "Updating installer..."

cd "$INSTALL_DIR"
git pull origin "$BRANCH"

else

git clone -b "$BRANCH" "$REPO" "$INSTALL_DIR"

fi

cd "$INSTALL_DIR"

chmod +x installer.sh

echo ""
echo "Launching installer..."
echo ""

bash installer.sh