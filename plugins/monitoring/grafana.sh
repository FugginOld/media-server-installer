PLUGIN_NAME="grafana"
PLUGIN_DESCRIPTION="Monitoring dashboards"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("prometheus")

install_service() {

echo "Installing Grafana..."

mkdir -p /opt/media-stack/config/grafana
mkdir -p /opt/media-stack/config/grafana/provisioning/datasources
mkdir -p /opt/media-stack/config/grafana/provisioning/dashboards
mkdir -p /opt/media-stack/config/grafana/dashboards

########################################
# Create Prometheus datasource
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
# Configure dashboard provisioning
########################################

cat <<EOF > /opt/media-stack/config/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: MediaStack
    folder: Media Server
    type: file
    options:
      path: /var/lib/grafana/dashboards
EOF

########################################
# Download system dashboard
########################################

curl -L \
https://grafana.com/api/dashboards/1860/revisions/37/download \
-o /opt/media-stack/config/grafana/dashboards/node-exporter.json

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_INSTALL_PLUGINS=grafana-worldmap-panel
    volumes:
      - ./config/grafana:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}