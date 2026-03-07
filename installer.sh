#!/usr/bin/env bash

set -e

STACK_DIR="/opt/media-stack"
PLUGIN_DIR="./plugins"

SELECTED_SERVICES=()

########################################
# Run preflight checks
########################################

bash ./scripts/preflight.sh

########################################
# Load core modules
########################################

source ./core/platform.sh
source ./core/directories.sh
source ./core/hardware.sh
source ./core/docker.sh
source ./core/config-wizard.sh

mkdir -p "$STACK_DIR"

########################################
# NEW: Ensure helper scripts are executable
########################################

chmod +x ./scripts/compose.sh 2>/dev/null || true
chmod +x ./scripts/updates.sh 2>/dev/null || true
chmod +x ./scripts/backup.sh 2>/dev/null || true
chmod +x ./scripts/health-monitor.sh 2>/dev/null || true

########################################
# Configuration wizard
########################################

run_configuration_wizard

if [ -f "$STACK_DIR/stack.env" ]; then
source "$STACK_DIR/stack.env"
fi

########################################
# Platform & hardware detection
########################################

detect_platform
detect_hardware

########################################
# Installation mode
########################################

MODE=$(whiptail \
--title "Media Stack Installer" \
--menu "Select installation mode" \
15 60 2 \
quick "Recommended stack" \
custom "Choose services manually" \
3>&1 1>&2 2>&3)

########################################
# Quick install services
########################################

if [ "$MODE" = "quick" ]; then

SELECTED_SERVICES=(
plex
radarr
sonarr
prowlarr
bazarr
sabnzbd
unpackerr
homepage
watchtower
tailscale
prometheus
nodeexporter
grafana
tautulli
plex-exporter
)

else

discover_plugins
select_services

fi

########################################
# Resolve dependencies
########################################

resolve_dependencies

########################################
# Initialize compose file
########################################

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

cat <<EOF > "$COMPOSE_FILE"
version: "3.9"

networks:
  media-network:

services:

EOF

########################################
# Install plugins
########################################

echo ""
echo "Installing services..."
echo ""

for SERVICE in "${SELECTED_SERVICES[@]}"
do
echo "Installing $SERVICE"
install_plugin "$SERVICE"
done

########################################
# Start containers
########################################

bash ./scripts/compose.sh up

########################################
# Post install automation
########################################

if [ -f ./scripts/post-install.sh ]; then
bash ./scripts/post-install.sh
fi

########################################
# NEW: Install container health monitor
########################################

if [ -f ./scripts/health-monitor.sh ]; then

CRON_JOB="*/5 * * * * /opt/media-server-installer/scripts/health-monitor.sh"

(crontab -l 2>/dev/null | grep -v health-monitor.sh; echo "$CRON_JOB") | crontab -

echo "Health monitor installed (runs every 5 minutes)."

fi

########################################
# Show dashboard
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "================================"
echo " Installation Complete"
echo "================================"
echo ""

echo "Dashboard:"
echo "http://$IP:3000"
echo ""

echo "Run:"
echo "media-stack services"
echo ""