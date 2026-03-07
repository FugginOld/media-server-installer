#!/usr/bin/env bash

########################################
# Post Install Automation
#
# Runs after containers are started to
# configure dashboards and monitoring.
########################################

INSTALL_DIR="/opt/media-server-installer"
STACK_DIR="/opt/media-stack"

echo ""
echo "================================"
echo " Running Post-Install Tasks"
echo "================================"
echo ""

########################################
# Wait for containers to start
########################################

echo "Waiting for containers to initialize..."
sleep 10

########################################
# Configure Grafana dashboards
########################################

if [ -f "$INSTALL_DIR/scripts/grafana-dynamic.sh" ]; then

echo ""
echo "Configuring Grafana dashboards..."

bash "$INSTALL_DIR/scripts/grafana-dynamic.sh"

fi

########################################
# Generate Homepage service list
########################################

if [ -f "$STACK_DIR/services.json" ]; then

echo ""
echo "Services registered:"
echo ""

cat "$STACK_DIR/services.json" \
| jq -r '.services[] | "\(.name) -> \(.url)"'

fi

########################################
# Start health monitoring if available
########################################

if [ -f "$INSTALL_DIR/scripts/health-monitor.sh" ]; then

echo ""
echo "Starting service health monitor..."

bash "$INSTALL_DIR/scripts/health-monitor.sh" &

fi

########################################
# Final status
########################################

echo ""
echo "Post-install configuration complete."
echo ""