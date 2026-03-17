#!/usr/bin/env bash
set -euo pipefail

########################################
# Import Grafana Dashboards via HTTP API
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/runtime.sh"

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"
DASHBOARDS_DIR="${STACK_DIR}/config/grafana/provisioning/dashboards"

########################################
# Wait for Grafana
########################################

wait_for_grafana() {
  local max_attempts=60
  local attempt=0
  
  log "Waiting for Grafana to be ready at $GRAFANA_URL..."
  while [ $attempt -lt $max_attempts ]; do
    if curl -sf "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
      log "Grafana is ready"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  
  error "Grafana health check timed out after ${max_attempts}s"
  return 1
}

########################################
# Import Dashboard
########################################

import_dashboard() {
  local dashboard_file="$1"
  local dashboard_name=$(basename "$dashboard_file" .json)
  
  if [ ! -f "$dashboard_file" ]; then
    error "Dashboard file not found: $dashboard_file"
    return 1
  fi
  
  log "Importing dashboard: $dashboard_name"
  
  # Read the dashboard JSON and wrap it for API import
  local dashboard_json=$(cat "$dashboard_file")
  
  # Import with admin credentials (wrapped format required by Grafana API)
  local response=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"dashboard\": $dashboard_json, \"overwrite\": true}" 2>&1)
  
  if echo "$response" | grep -q "\"status\":\"success\""; then
    local dashboard_url=$(echo "$response" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    log "✓ Dashboard imported: $dashboard_name (${dashboard_url:-/d/$dashboard_name})"
    return 0
  else
    error "Failed to import dashboard: $dashboard_name"
    error "Response: $response"
    return 1
  fi
}

########################################
# Main
########################################

if ! wait_for_grafana; then
  error "Failed to connect to Grafana"
  exit 1
fi

log "Importing Grafana dashboards from $DASHBOARDS_DIR..."

if [ ! -d "$DASHBOARDS_DIR" ]; then
  error "Dashboards directory not found: $DASHBOARDS_DIR"
  exit 1
fi

# Import all JSON dashboards
overall_success=true
for dashboard_file in "$DASHBOARDS_DIR"/*.json; do
  if ! import_dashboard "$dashboard_file"; then
    overall_success=false
  fi
done

if [ "$overall_success" = true ]; then
  log "All dashboards imported successfully"
  exit 0
else
  warn "Some dashboards failed to import"
  exit 1
fi
