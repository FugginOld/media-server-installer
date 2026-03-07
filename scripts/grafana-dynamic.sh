#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
CONFIG_DIR="$STACK_DIR/config/grafana"

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo ""
echo "================================"
echo " Grafana Auto Configuration"
echo "================================"
echo ""

########################################
# Wait for Grafana startup
########################################

echo "Waiting for Grafana..."

until curl -s "$GRAFANA_URL/api/health" >/dev/null; do
sleep 5
done

echo "Grafana detected."

########################################
# Create Prometheus datasource
########################################

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

########################################
# Import dashboards
########################################

DASHBOARD_DIR="$CONFIG_DIR/dashboards"

if [ -d "$DASHBOARD_DIR" ]; then

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