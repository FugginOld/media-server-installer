#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
# Post Install Tasks
########################################

LOG_DIR="$STACK_DIR/logs"

mkdir -p "$LOG_DIR"

########################################
# Wait for container helper
########################################

wait_for_container() {

local NAME="$1"
local TIMEOUT="${2:-60}"

log "Waiting for container: $NAME"

for ((i=0;i<TIMEOUT;i++))
do

if docker ps --format '{{.Names}}' | grep -Fxq "$NAME"; then
log "$NAME container started"
return 0
fi

sleep 1

done

log "Timeout waiting for $NAME"
return 1

}

########################################
# Wait for service HTTP endpoint
########################################

wait_for_http() {

local URL="$1"
local TIMEOUT="${2:-60}"

log "Waiting for service: $URL"

for ((i=0;i<TIMEOUT;i++))
do

if curl -fs "$URL" >/dev/null 2>&1; then
log "Service reachable: $URL"
return 0
fi

sleep 2

done

log "Service not reachable: $URL"
return 1

}

########################################
# Detect services from registry
########################################

if [[ -f "$SERVICE_REGISTRY" ]]; then

log "Checking registered services..."

jq -r '.services[] | "\(.name)|\(.url)"' "$SERVICE_REGISTRY" | while IFS="|" read -r NAME URL
do

wait_for_http "$URL" 30 || true

done

else

log "No services registry found"

fi

########################################
# Configure Grafana if present
########################################

if docker ps --format '{{.Names}}' | grep -Fxq "grafana"; then

log "Running Grafana configuration"

if [[ -f "$INSTALL_DIR/scripts/grafana-dynamic.sh" ]]; then
bash "$INSTALL_DIR/scripts/grafana-dynamic.sh" || true
fi

fi

########################################
# Generate Grafana provisioning
########################################

log "Generating Grafana provisioning configuration"

if [[ -f "$INSTALL_DIR/scripts/grafana-provisioning.sh" ]]; then
    bash "$INSTALL_DIR/scripts/grafana-provisioning.sh" >/dev/null 2>&1 || true
fi

########################################
# Import Grafana dashboards
########################################

log "Importing Grafana dashboards"

if [[ -f "$INSTALL_DIR/scripts/import-grafana-dashboards.sh" ]]; then
    bash "$INSTALL_DIR/scripts/import-grafana-dashboards.sh" || true
fi

########################################
# Generate Homepage dashboard
########################################

if [[ -f "$INSTALL_DIR/scripts/generate-homepage-config.sh" ]]; then

log "Generating Homepage dashboard configuration"

bash "$INSTALL_DIR/scripts/generate-homepage-config.sh" || true

fi

########################################
# Restart homepage container if needed
########################################

if docker ps --format '{{.Names}}' | grep -Fxq "homepage"; then

log "Restarting homepage container to load new configuration"

docker restart homepage >/dev/null 2>&1 || true

fi

########################################
# Cleanup old Docker artifacts
########################################

log "Cleaning unused Docker images"

docker image prune -f >/dev/null 2>&1 || true

########################################
# Completion
########################################

log "Post-install tasks completed"

echo ""
echo "Post-install configuration complete."
echo ""
