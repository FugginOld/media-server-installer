PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Metrics dashboard"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("prometheus")

install_service() {

echo "Installing Grafana..."

########################################
# Create config directories
########################################

mkdir -p /opt/media-stack/config/grafana
mkdir -p /opt/media-stack/config/grafana/provisioning/datasources
mkdir -p /opt/media-stack/config/grafana/dashboards

########################################
# Configure Prometheus datasource
########################################

cat <<EOF > /opt/media-stack/config/grafana/provisioning/datasources/prometheus.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3001:3000"
    volumes:
      - ./config/grafana:/var/lib/grafana
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Grafana" \
"http://localhost:3001" \
"Monitoring" \
"grafana.png"

}