#!/bin/bash

set -e

REPO="https://github.com/FugginOld/media-server-installer"
INSTALL_DIR="/opt/media-server-installer"

echo "Downloading Media Stack Installer..."

git clone $REPO $INSTALL_DIR

cd $INSTALL_DIR

chmod +x installer.sh
chmod +x media-stack

./installer.sh

cp media-stack /usr/local/bin/media-stack

echo ""
echo "Media Stack installed successfully."
echo "Use the command: media-stack"
