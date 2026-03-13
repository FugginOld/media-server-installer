#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
# Running Post-Install Tasks
########################################

echo ""
echo "================================"
echo "Running Post-Install Tasks"
echo "================================"
echo ""

########################################
# Allow containers time to initialize
########################################

echo "Waiting for containers to initialize..."
sleep 10

########################################
# Configure Grafana dashboards
########################################

if [ -f "$SCRIPT_DIR/grafana-dynamic.sh" ]; then

    echo ""
    echo "Configuring Grafana dashboards..."

    bash "$SCRIPT_DIR/grafana-dynamic.sh"

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
# Start health monitoring if available
########################################

if [ -f "$SCRIPT_DIR/health-monitor.sh" ]; then

    echo ""
    echo "Starting service health monitor..."

    mkdir -p "$STACK_DIR/logs"

    bash "$SCRIPT_DIR/health-monitor.sh" \
    >> "$STACK_DIR/logs/health-monitor.log" 2>&1 &

fi

########################################
# Final status
########################################

echo ""
echo "Post-install configuration complete."
echo ""
