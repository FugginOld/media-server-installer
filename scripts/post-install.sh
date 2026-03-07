#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
INSTALL_DIR="/opt/media-server-installer"

echo ""
echo "================================"
echo " Running Post Install Setup"
echo "================================"
echo ""

########################################
# Verify stack directory
########################################

if [ ! -d "$STACK_DIR" ]; then
    echo "Stack directory missing."
    exit 0
fi

########################################
# Ensure service registry exists
########################################

if [ ! -f "$STACK_DIR/services.json" ]; then

cat <<EOF > "$STACK_DIR/services.json"
{
  "services": []
}
EOF

echo "Initialized services registry."

fi

########################################
# Generate Homepage configuration
########################################

if [ -f "$INSTALL_DIR/plugins/system/homepage.sh" ]; then
    echo "Homepage plugin detected."
    echo "Homepage will auto-discover services."
fi

########################################
# Initialize health monitor
########################################

if [ -f "$INSTALL_DIR/scripts/health-monitor.sh" ]; then
    echo "Starting health monitor..."
    bash "$INSTALL_DIR/scripts/health-monitor.sh" &
fi

########################################
# Grafana integration
########################################

if [ -f "$INSTALL_DIR/scripts/grafana-dynamic.sh" ]; then
    echo "Generating Grafana dashboards..."
    bash "$INSTALL_DIR/scripts/grafana-dynamic.sh"
fi

########################################
# Verify containers
########################################

echo ""
echo "Verifying running containers..."

docker compose -f "$STACK_DIR/docker-compose.yml" ps

echo ""
echo "Post-install setup complete."
echo ""