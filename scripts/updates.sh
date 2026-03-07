#!/usr/bin/env bash

INSTALL_DIR="/opt/media-server-installer"

########################################
# NEW: Verify installer directory exists
########################################

if [ ! -d "$INSTALL_DIR" ]; then
echo "Media Stack installer directory not found:"
echo "$INSTALL_DIR"
echo ""
echo "The stack may not be installed yet."
exit 1
fi

echo ""
echo "Updating Media Stack"
echo ""

cd "$INSTALL_DIR" || exit

########################################
# NEW: Verify git is available
########################################

if ! command -v git >/dev/null 2>&1; then
echo "Git not found. Cannot update installer."
exit 1
fi

echo "Pulling latest installer..."
git pull

echo "Validating plugins..."
bash scripts/plugin-validator.sh

########################################
# NEW: Verify compose helper exists
########################################

if [ ! -f scripts/compose.sh ]; then
echo "compose.sh helper not found."
echo "Update aborted."
exit 1
fi

echo "Updating containers..."
bash scripts/compose.sh pull

echo "Restarting containers..."
bash scripts/compose.sh up

echo ""
echo "Update complete."