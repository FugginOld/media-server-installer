#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
# Post-install header
########################################

echo ""
echo "================================"
echo "Running Post-Install Tasks"
echo "================================"
echo ""

########################################
# Container health dashboard
########################################

show_container_health() {

echo ""
echo "Container Health Monitor"
echo "------------------------"

MAX_WAIT=120
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]
do

CONTAINERS=$(docker ps --format '{{.Names}}')

if [ -z "$CONTAINERS" ]; then
sleep 2
WAITED=$((WAITED+2))
continue
fi

CLEAR_OUTPUT=1

for C in $CONTAINERS
do

STATUS=$(docker inspect \
--format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
"$C" 2>/dev/null)

case "$STATUS" in

healthy|running)

printf "%-15s ✔ healthy\n" "$C"
;;

starting)

printf "%-15s ⟳ starting\n" "$C"
CLEAR_OUTPUT=0
;;

unhealthy)

printf "%-15s ✖ unhealthy\n" "$C"
CLEAR_OUTPUT=0
;;

*)

printf "%-15s ⟳ starting\n" "$C"
CLEAR_OUTPUT=0
;;

esac

done

echo ""

if [ "$CLEAR_OUTPUT" -eq 1 ]; then
echo "All containers healthy."
return
fi

sleep 3
WAITED=$((WAITED+3))

clear
echo "Container Health Monitor"
echo "------------------------"

done

echo "Health check timed out."

}

show_container_health

########################################
# Configure Grafana dashboards
########################################

GRAFANA_SCRIPT="$SCRIPT_DIR/grafana-dynamic.sh"

if [ -f "$GRAFANA_SCRIPT" ]; then

echo ""
echo "Configuring Grafana dashboards..."

bash "$GRAFANA_SCRIPT"

fi

########################################
# Display registered services
########################################

if [ -n "${SERVICE_REGISTRY:-}" ] && [ -f "$SERVICE_REGISTRY" ]; then

if command -v jq >/dev/null 2>&1; then

echo ""
echo "Registered services:"
echo ""

jq -r '.services[] | "\(.name) -> \(.url)"' "$SERVICE_REGISTRY" || true

echo ""

fi

fi

########################################
# Start health monitoring daemon
########################################

HEALTH_SCRIPT="$SCRIPT_DIR/health-monitor.sh"

if [ -f "$HEALTH_SCRIPT" ]; then

echo ""
echo "Starting background health monitor..."

mkdir -p "$STACK_DIR/logs"

bash "$HEALTH_SCRIPT" \
>> "$STACK_DIR/logs/health-monitor.log" 2>&1 &

fi

########################################
# Final message
########################################

echo ""
echo "Post-install configuration complete."
echo ""
