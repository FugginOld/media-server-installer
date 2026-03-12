#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

########################################
# Require root
########################################

if [ "$EUID" -ne 0 ]; then
echo "Reset must be run as root."
exit 1
fi

echo ""
echo "================================"
echo " Media Stack Reset"
echo "================================"
echo ""

########################################
# Confirm reset
########################################

read -rp "This will remove the entire Media Stack. Continue? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
echo "Reset cancelled."
exit 0
fi

########################################
# Offer backup before reset
########################################

read -rp "Create a backup before reset? (y/N): " BACKUP

if [[ "$BACKUP" =~ ^[Yy]$ ]]; then

if [ -f "$INSTALL_DIR/scripts/backup.sh" ]; then
bash "$INSTALL_DIR/scripts/backup.sh"
fi

fi

########################################
# Stop containers
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then

echo ""
echo "Stopping containers..."

bash "$INSTALL_DIR/scripts/compose.sh" down

fi

########################################
# Remove stack directory
########################################

if [ -d "$STACK_DIR" ]; then

echo ""
echo "Removing stack directory..."

rm -rf "$STACK_DIR"

fi

########################################
# Remove CLI command
########################################

if [ -f /usr/local/bin/media-stack ]; then
rm -f /usr/local/bin/media-stack
fi

########################################
# Optional Docker cleanup
########################################

if command -v docker >/dev/null 2>&1; then

########################################
# Remove containers
########################################

read -rp "Remove unused Docker containers? (y/N): " REMOVE_CONTAINERS

if [[ "$REMOVE_CONTAINERS" =~ ^[Yy]$ ]]; then
docker container prune -f
fi

########################################
# Remove images
########################################

read -rp "Remove unused Docker images? (y/N): " REMOVE_IMAGES

if [[ "$REMOVE_IMAGES" =~ ^[Yy]$ ]]; then
docker image prune -f
fi

########################################
# Remove volumes
########################################

read -rp "Remove unused Docker volumes? (y/N): " REMOVE_VOLUMES

if [[ "$REMOVE_VOLUMES" =~ ^[Yy]$ ]]; then
docker volume prune -f
fi

else

echo "Docker not installed — skipping container cleanup."

fi

########################################
# Done
########################################

echo ""
echo "Media Stack reset complete."
echo ""
echo "You can reinstall using:"
echo ""
echo "media-stack install"
echo ""
