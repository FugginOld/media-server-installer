#!/usr/bin/env bash

########################################
# Media Stack Update System
#
# Updates installer repository and
# Docker containers.
########################################

INSTALL_DIR="/opt/media-server-installer"

echo ""
echo "================================"
echo " Updating Media Stack"
echo "================================"
echo ""

########################################
# Ensure installer directory exists
########################################

if [ ! -d "$INSTALL_DIR" ]; then
echo "Installer directory not found."
exit 1
fi

cd "$INSTALL_DIR" || exit

########################################
# Update installer repository
########################################

echo "Pulling latest installer updates..."

git pull

########################################
# Validate plugins after update
########################################

echo ""
echo "Validating plugins..."

bash scripts/plugin-validator.sh

########################################
# Pull container updates
########################################

echo ""
echo "Updating container images..."

bash scripts/compose.sh pull

########################################
# Restart containers
########################################

echo ""
echo "Restarting containers..."

bash scripts/compose.sh up

echo ""
echo "Media Stack update complete."
echo ""