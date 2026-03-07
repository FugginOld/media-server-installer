#!/usr/bin/env bash

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

echo ""
echo "================================"
echo " Updating Media Stack"
echo "================================"
echo ""

########################################
# Ensure installer directory
########################################

if [ ! -d "$INSTALL_DIR" ]; then
    echo "Installer directory not found."
    exit 1
fi

cd "$INSTALL_DIR" || exit

########################################
# Update installer
########################################

echo "Pulling latest installer..."

git pull

if [ $? -ne 0 ]; then
    echo "Git update failed."
    exit 1
fi

########################################
# Validate plugins
########################################

echo ""
echo "Validating plugins..."

bash scripts/plugin-validator.sh

if [ $? -ne 0 ]; then
    echo "Plugin validation failed."
    exit 1
fi

########################################
# Update containers
########################################

echo ""
echo "Pulling container updates..."

bash scripts/compose.sh pull

########################################
# Restart stack
########################################

echo ""
echo "Restarting containers..."

bash scripts/compose.sh restart

########################################
# Show status
########################################

echo ""
echo "Current container status:"
echo ""

bash scripts/compose.sh status

echo ""
echo "Update complete."
echo ""