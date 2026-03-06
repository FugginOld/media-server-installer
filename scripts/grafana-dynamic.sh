#!/usr/bin/env bash

STACK_DIR="/opt/media-stack"
REGISTRY_FILE="$STACK_DIR/services.json"
DASHBOARD_DIR="$STACK_DIR/config/grafana/dashboards"

mkdir -p "$DASHBOARD_DIR"

########################################
# Helper: check service
########################################

has_service() {

jq -e ".services[] | select(.name == \"$1\")" \
"$REGISTRY_FILE" >/dev/null

}

########################################
# Install system dashboard
########################################

if has_service "NodeExporter"; then

echo "Installing system monitoring dashboard..."

curl -L \
https://grafana.com/api/dashboards/1860/revisions/37/download \
-o "$DASHBOARD_DIR/node-exporter.json"

fi

########################################
# Install Plex dashboard
########################################

if has_service "Plex"; then

echo "Installing Plex dashboard..."

curl -L \
https://grafana.com/api/dashboards/14161/revisions/1/download \
-o "$DASHBOARD_DIR/plex.json"

fi

########################################
# Install ARR dashboards
########################################

if has_service "Radarr"; then

echo "Installing Radarr dashboard..."

curl -L \
https://grafana.com/api/dashboards/15007/revisions/1/download \
-o "$DASHBOARD_DIR/radarr.json"

fi

if has_service "Sonarr"; then

echo "Installing Sonarr dashboard..."

curl -L \
https://grafana.com/api/dashboards/15008/revisions/1/download \
-o "$DASHBOARD_DIR/sonarr.json"

fi

########################################
# Install Prometheus dashboard
########################################

if has_service "Prometheus"; then

echo "Installing Prometheus dashboard..."

curl -L \
https://grafana.com/api/dashboards/3662/revisions/2/download \
-o "$DASHBOARD_DIR/prometheus.json"

fi

echo "Grafana dashboard provisioning complete"