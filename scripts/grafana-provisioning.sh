#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/runtime.sh"

GRAFANA_CONFIG="$STACK_DIR/config/grafana"
PROVISIONING_DIR="$GRAFANA_CONFIG/provisioning"
DATASOURCES_DIR="$PROVISIONING_DIR/datasources"
DASHBOARDS_DIR="$PROVISIONING_DIR/dashboards"

mkdir -p "$DATASOURCES_DIR" "$DASHBOARDS_DIR"

log_info "Generating Grafana provisioning configs..."

########################################
# Prometheus datasource
########################################

log_info "Creating Prometheus datasource config..."
cat > "$DATASOURCES_DIR/prometheus.yaml" <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

########################################
# Dashboard provider (for HTTP API imports)
########################################

log_info "Creating dashboard provider config..."
cat > "$PROVISIONING_DIR/dashboards.yaml" <<'EOF'
apiVersion: 1

providers:
  - name: 'Media Stack Dashboards'
    orgId: 1
    folder: 'Media Stack'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

########################################
# Generate dashboard JSON files
########################################

log_info "Generating dashboard JSON files..."

# System Performance metrics
cat > "$DASHBOARDS_DIR/system-metrics.json" <<'EOF'
{
  "title": "System Performance",
  "description": "Server CPU, Memory, and Network metrics",
  "tags": ["system", "infrastructure"],
  "timezone": "browser",
  "schemaVersion": 27,
  "version": 0,
  "refresh": "30s",
  "uid": "system-metrics",
  "panels": [
    {
      "title": "CPU Usage (%)",
      "type": "gauge",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "id": 1,
      "datasource": "Prometheus",
      "targets": [{"expr": "avg(100 - (rate(node_cpu_seconds_total{mode=\\\"idle\\\"}[5m]) * 100))", "refId": "A"}]
    },
    {
      "title": "Memory Usage (%)",
      "type": "gauge",
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
      "id": 2,
      "datasource": "Prometheus",
      "targets": [{"expr": "avg((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)", "refId": "A"}]
    },
    {
      "title": "Load Average",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
      "id": 3,
      "datasource": "Prometheus",
      "targets": [
        {"expr": "node_load1", "refId": "A", "legendFormat": "1m"},
        {"expr": "node_load5", "refId": "B", "legendFormat": "5m"},
        {"expr": "node_load15", "refId": "C", "legendFormat": "15m"}
      ]
    },
    {
      "title": "Network I/O",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4},
      "id": 4,
      "datasource": "Prometheus",
      "targets": [
        {"expr": "rate(node_network_receive_bytes_total[5m]) * 8", "refId": "A", "legendFormat": "In"},
        {"expr": "rate(node_network_transmit_bytes_total[5m]) * 8", "refId": "B", "legendFormat": "Out"}
      ]
    }
  ]
}
EOF

# Plex Metrics
cat > "$DASHBOARDS_DIR/plex-metrics.json" <<'EOF'
{
  "title": "Plex Server Metrics",
  "description": "Plex streaming activity and performance",
  "tags": ["plex", "media"],
  "timezone": "browser",
  "schemaVersion": 27,
  "version": 0,
  "refresh": "30s",
  "uid": "plex-metrics",
  "panels": [
    {
      "title": "Active Streams",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "id": 1,
      "datasource": "Prometheus",
      "targets": [{"expr": "plex_streams_active or vector(0)", "refId": "A"}]
    },
    {
      "title": "Transcode Sessions",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
      "id": 2,
      "datasource": "Prometheus",
      "targets": [{"expr": "plex_transcode_sessions or vector(0)", "refId": "A"}]
    },
    {
      "title": "Streaming Bandwidth",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
      "id": 3,
      "datasource": "Prometheus",
      "targets": [{"expr": "rate(plex_bandwidth_bytes[5m]) * 8", "refId": "A", "legendFormat": "{{stream_type}}"}]
    }
  ]
}
EOF

# User Activity
cat > "$DASHBOARDS_DIR/user-activity.json" <<'EOF'
{
  "title": "User Activity",
  "description": "User activity and watch history from Tautulli",
  "tags": ["tautulli", "users"],
  "timezone": "browser",
  "schemaVersion": 27,
  "version": 0,
  "refresh": "30s",
  "uid": "user-activity",
  "panels": [
    {
      "title": "Active Users",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "id": 1,
      "datasource": "Prometheus",
      "targets": [{"expr": "count(tautulli_user_sessions_active) or vector(0)", "refId": "A"}]
    },
    {
      "title": "Currently Watching",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
      "id": 2,
      "datasource": "Prometheus",
      "targets": [{"expr": "count(tautulli_user_watching) or vector(0)", "refId": "A"}]
    },
    {
      "title": "Total Watches",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
      "id": 3,
      "datasource": "Prometheus",
      "targets": [{"expr": "tautulli_account_watches_total or vector(0)", "refId": "A", "legendFormat": "{{account}}"}]
    }
  ]
}
EOF

# Stack Health
cat > "$DASHBOARDS_DIR/stack-health.json" <<'EOF'
{
  "title": "Stack Health",
  "description": "Container and service health status",
  "tags": ["docker", "infrastructure"],
  "timezone": "browser",
  "schemaVersion": 27,
  "version": 0,
  "refresh": "30s",
  "uid": "stack-health",
  "panels": [
    {
      "title": "Total Containers",
      "type": "stat",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "id": 1,
      "datasource": "Prometheus",
      "targets": [{"expr": "count(container_last_seen) or vector(0)", "refId": "A"}]
    },
    {
      "title": "Container Memory Usage",
      "type": "timeseries",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
      "id": 2,
      "datasource": "Prometheus",
      "targets": [{"expr": "container_memory_usage_bytes or vector(0)", "refId": "A", "legendFormat": "{{name}}"}]
    }
  ]
}
EOF

log_info "Grafana provisioning configs generated successfully"
log_info "- Datasources: $DATASOURCES_DIR/prometheus.yaml"
log_info "- Dashboard provider: $PROVISIONING_DIR/dashboards.yaml"
log_info "- Dashboard files: $DASHBOARDS_DIR/"
ls -1 "$DASHBOARDS_DIR"/*.json 2>/dev/null | while read f; do log_info "  - $(basename "$f")"; done

exit 0
