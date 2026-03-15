#!/usr/bin/env bash
set -euo pipefail

########################################
# Resolve install directory
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"

########################################
# Load runtime and libraries
########################################

source "$INSTALL_DIR/lib/runtime.sh"
source "$LIB_DIR/compose.sh"

########################################
# Updating Media Stack
########################################

echo ""
echo "================================"
echo "Updating Media Stack"
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

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
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
# Show recent changes
########################################

echo ""
echo "Recent changes:"
git --no-pager log --oneline -5 || true

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

compose_validate

########################################
# Pull container updates
########################################

echo ""
echo "Updating container images..."

compose_pull

########################################
# Restart containers
########################################

echo ""
echo "Restarting containers..."

compose_restart

echo ""
echo "Media Stack update complete."
echo ""