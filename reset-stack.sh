#!/usr/bin/env bash

set -e

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"
CLI="/usr/local/bin/media-stack"
NETWORK="media-network"

echo ""
echo "======================================"
echo " Media Stack Developer Reset"
echo "======================================"
echo ""

########################################
# Stop running containers
########################################

echo "Stopping containers..."

docker ps -a --format "{{.Names}}" | grep -E \
"plex|radarr|sonarr|prowlarr|bazarr|sabnzbd|unpackerr|watchtower|tailscale|homepage|prometheus|grafana|nodeexporter|tautulli|plex-exporter|webinstaller" \
| xargs -r docker rm -f

echo "Containers removed"

########################################
# Remove docker network
########################################

echo "Removing docker network..."

docker network rm $NETWORK 2>/dev/null || true

########################################
# Remove installer directories
########################################

echo "Removing stack directories..."

rm -rf $STACK_DIR
rm -rf $INSTALL_DIR

########################################
# Remove CLI command
########################################

echo "Removing CLI command..."

rm -f $CLI

########################################
# Optional: clean docker images
########################################

read -p "Remove unused Docker images? (y/N): " CLEAN

if [[ "$CLEAN" == "y" || "$CLEAN" == "Y" ]]; then
    docker system prune -a -f
fi

echo ""
echo "Reset complete."
echo ""
echo "You can reinstall using:"
echo ""
echo "curl -fsSL https://raw.githubusercontent.com/FugginOld/media-server-installer/main/install.sh | bash"
echo ""