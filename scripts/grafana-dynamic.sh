#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
#Grafana Dynamic Configuration
########################################

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo ""
echo "================================"
echo "Configuring Grafana"
echo "================================"
echo ""

########################################
#Wait for Grafana container
########################################

bash "$INSTALL_DIR/scripts/wait-for-container.sh" grafana 120 || exit 0

########################################
#Wait for API
########################################

echo "Waiting for Grafana API..."

for _ in {1..30}
do
if curl -sf "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
echo "Grafana API ready"
break
fi

sleep 2
done

########################################
#Create Prometheus datasource
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
}' >/dev/null || true

echo "Datasource created"

echo ""
echo "Grafana configuration complete."
echo ""
