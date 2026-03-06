#!/usr/bin/env bash

INSTALL_DIR="/opt/media-server-installer"

echo ""
echo "Updating Media Stack"
echo ""

cd "$INSTALL_DIR" || exit

echo "Pulling latest installer..."
git pull

echo "Validating plugins..."
bash scripts/plugin-validator.sh

echo "Updating containers..."
bash scripts/compose.sh pull

echo "Restarting containers..."
bash scripts/compose.sh up

echo ""
echo "Update complete."