#!/usr/bin/env bash

########################################
# Media Stack Health Monitor
#
# Continuously checks registered
# services to ensure they are reachable.
########################################

STACK_DIR="/opt/media-stack"
REGISTRY_FILE="$STACK_DIR/services.json"

CHECK_INTERVAL=60

########################################
# Verify registry exists
########################################

if [ ! -f "$REGISTRY_FILE" ]; then
echo "Service registry not found."
exit 1
fi

echo ""
echo "Media Stack Health Monitor started."
echo "Checking services every $CHECK_INTERVAL seconds."
echo ""

########################################
# Monitoring loop
########################################

while true
do

SERVICES=$(jq -c '.services[]' "$REGISTRY_FILE")

for SERVICE in $SERVICES
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