#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

########################################
#Media Stack Health Monitor
########################################

CHECK_INTERVAL=60

########################################
#Ensure dependencies exist
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
#Verify registry exists
########################################

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo "Service registry not found."
exit 1
fi

########################################
#Handle shutdown
########################################

trap "echo ''; echo 'Health monitor stopped.'; exit 0" SIGINT SIGTERM

echo ""
echo "Media Stack Health Monitor started."
echo "Checking services every $CHECK_INTERVAL seconds."
echo ""

########################################
#Monitoring loop
########################################

while true
do

jq -r '.services[] | "\(.name)|\(.url)"' "$SERVICE_REGISTRY" | while IFS="|" read -r NAME URL
do

########################################
#Check service availability
########################################

if curl -fs "$URL" >/dev/null 2>&1; then
echo "$(date '+%H:%M:%S') OK: $NAME"
else
echo "$(date '+%H:%M:%S') WARNING: $NAME not responding"
fi

done

########################################
#Wait before next check
########################################

sleep "$CHECK_INTERVAL"

done
