#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
# Wait For Container Health
#
# Usage:
# wait_for_container <container> [timeout]
########################################

CONTAINER="$1"
TIMEOUT="${2:-120}"

if [ -z "$CONTAINER" ]; then
echo "Usage: wait_for_container <container> [timeout]"
exit 1
fi

echo "Waiting for container: $CONTAINER"

ELAPSED=0

while true
do

STATUS=$(docker inspect \
--format='{{.State.Health.Status}}' \
"$CONTAINER" 2>/dev/null)

if [ "$STATUS" = "healthy" ]; then
echo "$CONTAINER is healthy"
return 0
fi

if [ "$STATUS" = "running" ]; then
echo "$CONTAINER running (no healthcheck)"
return 0
fi

sleep 2
ELAPSED=$((ELAPSED+2))

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
echo "Timeout waiting for $CONTAINER"
return 1
fi

done
