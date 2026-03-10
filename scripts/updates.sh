#!/usr/bin/env bash

########################################
# Media Stack Update System
#
# Updates the installer repository
# and refreshes Docker containers.
########################################

set -e

########################################
# Determine installer directory
########################################

if [ -z "$INSTALL_DIR" ]; then
INSTALL_DIR="/opt/media-server-installer"
fi

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

echo ""
echo "================================"
echo " Updating Media Stack"
echo "================================"
echo ""

########################################
# Ensure git exists
########################################

if ! command -v git >/dev/null 2>&1; then
echo "Git is required for updates."
exit 1
fi

########################################
# Ensure installer repository exists
########################################

if [ ! -d "$INSTALL_DIR/.git" ]; then
echo "Installer repository not found: $INSTALL_DIR"
exit 1
fi

cd "$INSTALL_DIR"

########################################
# Update installer repository
########################################

echo "Pulling latest installer updates..."

if ! git pull --ff-only; then
echo "Failed to update installer repository."
exit 1
fi

########################################
# Validate plugins after update
########################################

echo ""
echo "Validating plugins..."

bash "$INSTALL_DIR/scripts/plugin-validator.sh"

########################################
# Validate docker compose configuration
########################################

echo ""
echo "Validating compose configuration..."

bash "$INSTALL_DIR/scripts/compose.sh" validate

########################################
# Pull container updates
########################################

echo ""
echo "Updating container images..."

bash "$INSTALL_DIR/scripts/compose.sh" pull

########################################
# Restart containers
########################################

echo ""
echo "Restarting containers..."

bash "$INSTALL_DIR/scripts/compose.sh" restart

echo ""
echo "Media Stack update complete."
echo ""