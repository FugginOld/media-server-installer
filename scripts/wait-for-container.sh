#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Wait For Container Health
#
#Usage:
#wait-for-container.sh <container> [timeout]
########################################

if [ $# -lt 1 ]; then
echo "Usage: wait-for-container.sh <container> [timeout]"
exit 1
fi

CONTAINER="$1"
TIMEOUT="${2:-120}"

echo "Waiting for container: $CONTAINER"

ELAPSED=0

while true
do

STATUS="$(docker inspect \
--format='{{.State.Health.Status}}' \
"$CONTAINER" 2>/dev/null || true)"

########################################
#Healthy container
########################################

if [ "$STATUS" = "healthy" ]; then
echo "$CONTAINER is healthy"
exit 0
fi

########################################
#Running but no healthcheck
########################################

if [ "$STATUS" = "running" ]; then
echo "$CONTAINER running (no healthcheck)"
exit 0
fi

sleep 2
ELAPSED=$((ELAPSED + 2))

########################################
#Timeout check
########################################

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
echo "Timeout waiting for $CONTAINER"
exit 1
fi

done
