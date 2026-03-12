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
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

CHECK_INTERVAL=60

########################################
# Ensure dependencies exist
########################################

if ! command -v jq >/dev/null 2>&1; then
echo "jq is required for health monitoring."
exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
echo "curl is required for health monitoring."
exit 1
fi

########################################
# Verify registry exists
########################################

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo "Service registry not found."
exit 1
fi

########################################
# Handle shutdown
########################################

trap "echo ''; echo 'Health monitor stopped.'; exit 0" SIGINT SIGTERM

echo ""
echo "Media Stack Health Monitor started."
echo "Checking services every $CHECK_INTERVAL seconds."
echo ""

########################################
# Monitoring loop
########################################

while true
do

jq -c '.services[]' "$SERVICE_REGISTRY" | while read -r SERVICE
do

NAME=$(echo "$SERVICE" | jq -r '.name')
URL=$(echo "$SERVICE" | jq -r '.url')

########################################
# Check service availability
########################################

if curl -fs "$URL" >/dev/null 2>&1; then

echo "$(date '+%H:%M:%S') OK: $NAME"

else

echo "$(date '+%H:%M:%S') WARNING: $NAME not responding"

fi

done

########################################
# Wait before next check
########################################

sleep "$CHECK_INTERVAL"

done
