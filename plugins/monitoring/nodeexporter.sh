PLUGIN_NAME="nodeexporter"
PLUGIN_DESCRIPTION="System metrics exporter"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Node Exporter..."

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
    ports:
      - "9100:9100"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:9100/metrics"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"NodeExporter" \
"http://localhost:9100/metrics" \
"Monitoring" \
"nodeexporter.png"

}