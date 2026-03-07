PLUGIN_NAME="plex-exporter"
PLUGIN_DESCRIPTION="Plex metrics exporter"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("plex" "prometheus")

install_service() {

echo "Installing Plex Exporter..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/plex-exporter

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  plex-exporter:
    image: granra/plex_exporter
    container_name: plex-exporter
    environment:
      - PLEX_SERVER=http://plex:32400
      - PLEX_TOKEN=
    ports:
      - "9594:9594"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:9594/metrics"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Plex Exporter" \
"http://localhost:9594/metrics" \
"Monitoring" \
"plex-exporter.png"

}