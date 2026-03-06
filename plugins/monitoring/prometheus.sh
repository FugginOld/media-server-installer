PLUGIN_NAME="prometheus"
PLUGIN_DESCRIPTION="Metrics monitoring system"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("nodeexporter")

install_service() {

echo "Installing Prometheus..."

mkdir -p /opt/media-stack/config/prometheus

########################################
# Create Prometheus configuration
########################################

cat <<EOF > /opt/media-stack/config/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']

  - job_name: 'plex'
    static_configs:
      - targets: ['plex-exporter:9594']
EOF

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    volumes:
      - ./config/prometheus:/etc/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:9090"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}