#!/usr/bin/env bash

########################################
# Grafana Dynamic Configuration
#
# Automatically configures Grafana
# after installation.
########################################

set -e

########################################
# Determine installer directory
########################################

if [ -z "$INSTALL_DIR" ]; then
INSTALL_DIR="/opt/media-server-installer"
fi

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

CONFIG_DIR="$CONFIG_DIR/grafana"

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

########################################
# Ensure dependencies
########################################

if ! command -v curl >/dev/null 2>&1; then
echo "curl is required for Grafana configuration."
exit 1
fi

########################################
# Wait for Grafana
########################################

echo ""
echo "================================"
echo " Configuring Grafana"
echo "================================"
echo ""

echo "Waiting for Grafana service..."

MAX_RETRIES=24
COUNT=0

until curl -s "$GRAFANA_URL/api/health" >/dev/null 2>&1
do

sleep 5
COUNT=$((COUNT+1))

if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
echo "Grafana did not start within expected time."
exit 1
fi

done

echo "Grafana is online."

########################################
# Check if datasource already exists
########################################

if curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" \
"$GRAFANA_URL/api/datasources" | jq -e '.[] | select(.name=="Prometheus")' >/dev/null 2>&1
then

echo "Prometheus datasource already exists."

else

echo ""
echo "Creating Prometheus datasource..."

curl -s -X POST "$GRAFANA_URL/api/datasources" \
-H "Content-Type: application/json" \
-u "$GRAFANA_USER:$GRAFANA_PASS" \
-d '{
"name":"Prometheus",
"type":"prometheus",
"url":"http://prometheus:9090",
"access":"proxy",
"isDefault":true
}' >/dev/null

echo "Datasource created."

fi

########################################
# Import dashboards
########################################

DASHBOARD_DIR="$CONFIG_DIR/dashboards"

if [ -d "$DASHBOARD_DIR" ]; then

FILES=$(find "$DASHBOARD_DIR" -name "*.json")

if [ -n "$FILES" ]; then

echo ""
echo "Importing dashboards..."

for DASHBOARD in $FILES
do

curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
-H "Content-Type: application/json" \
-u "$GRAFANA_USER:$GRAFANA_PASS" \
-d @"$DASHBOARD" >/dev/null

echo "Imported $(basename "$DASHBOARD")"

done

fi

fi

echo ""
echo "Grafana configuration complete."
echo ""