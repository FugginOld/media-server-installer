# Media Stack Monitoring Plugins

The `plugins/monitoring/` directory contains services responsible for monitoring,
metrics collection, and analytics for the Media Stack.

These services provide visibility into:

- system performance
- container performance
- Plex usage statistics
- network activity
- hardware utilization

The monitoring stack uses a standard observability architecture based on Prometheus and Grafana.

Typical monitoring architecture:

nodeexporter
plex-exporter
glances
      ↓
   Prometheus
      ↓
    Grafana

This architecture collects metrics from multiple sources and presents them through visual dashboards.

---

# Monitoring Plugins

## Prometheus

Prometheus is the metrics collection engine used by the Media Stack.

It periodically scrapes metrics from exporters and stores them in a time-series database.

Responsibilities:

- collect metrics from exporters
- store time-series monitoring data
- provide query interface for Grafana

Prometheus collects data from:

- nodeexporter
- plex-exporter
- glances

Default interface:

http://SERVER-IP:9090

---

## Grafana

Grafana provides the visualization layer for the monitoring system.

It connects to Prometheus and displays collected metrics in customizable dashboards.

Features:

- system performance dashboards
- network monitoring
- Plex streaming analytics
- resource usage visualization

Default interface:

http://SERVER-IP:3000

Default credentials:

admin / admin

After installation, Grafana is automatically configured by the script:

scripts/grafana-dynamic.sh

This script creates the Prometheus datasource and prepares dashboards.

---

## Node Exporter

Node Exporter provides system-level metrics for Prometheus.

It exposes hardware and operating system metrics such as:

- CPU usage
- memory usage
- disk I/O
- filesystem usage
- network traffic

These metrics allow Grafana dashboards to display the real-time performance of the server running the Media Stack.

Default metrics endpoint:

http://SERVER-IP:9100/metrics

---

## Plex Exporter

Plex Exporter collects metrics from Plex and exposes them to Prometheus.

This allows the monitoring system to track streaming activity.

Metrics include:

- number of active streams
- transcoding activity
- Plex bandwidth usage
- concurrent users

These metrics can be visualized in Grafana dashboards.

Metrics endpoint:

http://SERVER-IP:9594/metrics

---

## Tautulli

Tautulli provides advanced analytics for Plex.

It monitors Plex server activity and provides detailed insights into media usage.

Features:

- user playback history
- bandwidth monitoring
- stream statistics
- device statistics
- media popularity tracking

Tautulli can also provide geographic viewing data for dashboards.

Default interface:

http://SERVER-IP:8181

---

## Glances

Glances provides real-time system monitoring with a web interface.

It displays live system statistics including:

- CPU usage
- RAM usage
- disk utilization
- network traffic
- running processes

Glances also exposes metrics that Prometheus can scrape.

Default interface:

http://SERVER-IP:61208

---

# Monitoring Capabilities

When all monitoring plugins are installed, the Media Stack provides complete observability including:

System Metrics

- CPU utilization
- memory usage
- disk activity
- network throughput

Application Metrics

- Plex streaming activity
- number of users
- transcoding events

Infrastructure Metrics

- container health
- system load
- resource usage trends

---

# Summary

The monitoring plugins provide full observability for the Media Stack.

By combining Prometheus, Grafana, and several exporters, the stack is capable of tracking both system performance and media server usage.