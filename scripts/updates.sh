#!/usr/bin/env bash

########################################
# Media Stack Update System
#
# Updates the installer repository
# and refreshes Docker containers.
########################################

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
# Ensure installer directory exists
########################################

if [ ! -d "$INSTALL_DIR/.git" ]; then
echo "Installer repository not found: $INSTALL_DIR"
exit 1
fi

cd "$INSTALL_DIR" || exit 1

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

bash "$INSTALL_DIR/scripts/compose.sh" up

echo ""
echo "Media Stack update complete."
echo ""