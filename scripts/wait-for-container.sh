#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
# Wait for container to become ready
########################################

CONTAINER="${1:-}"
TIMEOUT="${2:-120}"
INTERVAL=5

if [ -z "$CONTAINER" ]; then
echo "Usage: wait-for-container.sh <container-name> [timeout]"
exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
echo "Docker not installed."
exit 1
fi

echo ""
echo "Waiting for container: $CONTAINER"
echo "Timeout: ${TIMEOUT}s"
echo ""

START_TIME=$(date +%s)

while true
do

CURRENT_TIME=$(date +%s)
ELAPSED=$((CURRENT_TIME - START_TIME))

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
echo "Timeout waiting for container: $CONTAINER"
exit 1
fi

########################################
# Check if container exists
########################################

if ! docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER"; then
echo "Container not created yet: $CONTAINER"
sleep "$INTERVAL"
continue
fi

########################################
# Get container state
########################################

STATUS=$(docker inspect \
--format '{{.State.Status}}' \
"$CONTAINER" 2>/dev/null || echo "unknown")

HEALTH=$(docker inspect \
--format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
"$CONTAINER" 2>/dev/null || echo "unknown")

########################################
# Health check containers
########################################

if [ "$HEALTH" = "healthy" ]; then
echo "Container healthy: $CONTAINER"
exit 0
fi

########################################
# Non-healthcheck containers
########################################

if [ "$HEALTH" = "none" ] && [ "$STATUS" = "running" ]; then
echo "Container running: $CONTAINER"
exit 0
fi

########################################
# Status output
########################################

echo "Waiting... status=$STATUS health=$HEALTH"

sleep "$INTERVAL"

done