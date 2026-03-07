#!/usr/bin/env bash

########################################
# Grafana Dynamic Configuration
#
# Automatically configures Grafana
# after installation.
########################################

STACK_DIR="/opt/media-stack"
CONFIG_DIR="$STACK_DIR/config/grafana"

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo ""
echo "================================"
echo " Configuring Grafana"
echo "================================"
echo ""

########################################
# Wait for Grafana to start
########################################

echo "Waiting for Grafana service..."

until curl -s "$GRAFANA_URL/api/health" >/dev/null 2>&1
do
sleep 5
done

echo "Grafana is online."

########################################
# Create Prometheus datasource
########################################

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

########################################
# Import dashboards if available
########################################

DASHBOARD_DIR="$CONFIG_DIR/dashboards"

if [ -d "$DASHBOARD_DIR" ]; then

echo ""
echo "Importing dashboards..."

for DASHBOARD in "$DASHBOARD_DIR"/*.json
do

curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
-H "Content-Type: application/json" \
-u "$GRAFANA_USER:$GRAFANA_PASS" \
-d @"$DASHBOARD" >/dev/null

echo "Imported $(basename "$DASHBOARD")"

done

fi

echo ""
echo "Grafana configuration complete."
echo ""