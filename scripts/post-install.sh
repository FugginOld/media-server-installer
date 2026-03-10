#!/usr/bin/env bash

########################################
# Media Stack Post Install Automation
#
# Runs after containers start to
# configure dashboards and monitoring.
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
echo " Running Post-Install Tasks"
echo "================================"
echo ""

########################################
# Ensure log directory exists
########################################

mkdir -p "$LOG_DIR"

########################################
# Wait for containers to initialize
########################################

echo "Waiting for containers to initialize..."
sleep 20

########################################
# Configure Grafana dashboards
########################################

if [ -f "$INSTALL_DIR/scripts/grafana-dynamic.sh" ]; then

echo ""
echo "Configuring Grafana dashboards..."

bash "$INSTALL_DIR/scripts/grafana-dynamic.sh"

fi

########################################
# Display registered services
########################################

if [ -f "$SERVICE_REGISTRY" ] && command -v jq >/dev/null 2>&1; then

echo ""
echo "Registered services:"
echo ""

jq -r '.services[] | "\(.name) -> \(.url)"' "$SERVICE_REGISTRY"

echo ""

fi

########################################
# Start health monitoring
########################################

if [ -f "$INSTALL_DIR/scripts/health-monitor.sh" ]; then

echo ""
echo "Starting service health monitor..."

bash "$INSTALL_DIR/scripts/health-monitor.sh" \
>> "$LOG_DIR/health-monitor.log" 2>&1 &

fi

########################################
# Display container status
########################################

if command -v docker >/dev/null 2>&1; then

echo ""
echo "Container status:"
echo ""

bash "$INSTALL_DIR/scripts/compose.sh" status

fi

########################################
# Final status
########################################

echo ""
echo "Post-install configuration complete."
echo ""