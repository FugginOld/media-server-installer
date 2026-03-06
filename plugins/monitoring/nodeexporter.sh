PLUGIN_NAME="nodeexporter"
PLUGIN_DESCRIPTION="System metrics exporter"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Node Exporter..."

cat <<EOF >> /opt/media-stack/docker-compose.yml

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    ports:
      - "9100:9100"
    pid: host
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:9100/metrics"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}