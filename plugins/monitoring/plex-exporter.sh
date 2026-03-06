PLUGIN_NAME="plexexporter"
PLUGIN_DESCRIPTION="Plex Prometheus metrics exporter"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("plex")

install_service() {

echo "Installing Plex Prometheus Exporter..."

cat <<EOF >> /opt/media-stack/docker-compose.yml

  plex-exporter:
    image: ghcr.io/teticio/plex-exporter
    container_name: plex-exporter
    environment:
      - PLEX_URL=http://plex:32400
    ports:
      - "9594:9594"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:9594/metrics"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}