#!/usr/bin/env bash

########################################
# Media Stack Reset
#
# Completely removes the Media Stack
# installation so it can be reinstalled.
########################################

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"

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
# Stop containers
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then

echo ""
echo "Stopping containers..."

cd "$STACK_DIR" || exit
docker compose down

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
# Optional: remove containers
########################################

read -rp "Remove unused Docker containers? (y/N): " REMOVE_CONTAINERS

if [[ "$REMOVE_CONTAINERS" == "y" || "$REMOVE_CONTAINERS" == "Y" ]]; then

docker container prune -f

fi

########################################
# Optional: remove images
########################################

read -rp "Remove unused Docker images? (y/N): " REMOVE_IMAGES

if [[ "$REMOVE_IMAGES" == "y" || "$REMOVE_IMAGES" == "Y" ]]; then

docker image prune -f

fi

########################################
# Optional: remove volumes
########################################

read -rp "Remove unused Docker volumes? (y/N): " REMOVE_VOLUMES

if [[ "$REMOVE_VOLUMES" == "y" || "$REMOVE_VOLUMES" == "Y" ]]; then

docker volume prune -f

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