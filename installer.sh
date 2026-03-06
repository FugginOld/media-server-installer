#!/usr/bin/env bash

set -e

STACK_DIR="/opt/media-stack"
PLUGIN_DIR="./plugins"

SELECTED_SERVICES=()

source ./core/platform.sh
source ./core/directories.sh
source ./core/hardware.sh
source ./core/docker.sh
source ./core/config-wizard.sh

########################################
# Run config wizard
########################################

run_configuration_wizard

source /opt/media-stack/stack.env

########################################
# Install mode
########################################

MODE=$(whiptail \
--title "Install Mode" \
--menu "Choose installation type" \
15 60 2 \
quick "Recommended media stack" \
custom "Select services manually" \
3>&1 1>&2 2>&3)

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
# Install services
########################################

for SERVICE in "${SELECTED_SERVICES[@]}"
do
install_plugin "$SERVICE"
done

########################################
# Start stack
########################################

cd $STACK_DIR
docker compose up -d

########################################
# Post install automation
########################################

bash ./scripts/post-install.sh

########################################
# Show dashboard
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Installation complete!"
echo ""
echo "Dashboard:"
echo "http://$IP:3000"
echo ""
echo "Use command:"
echo "media-stack services"
echo ""