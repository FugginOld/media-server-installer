PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Service dashboard"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Homepage Dashboard..."

mkdir -p /opt/media-stack/config/homepage

########################################
# Create Homepage configuration
########################################

cat <<EOF > /opt/media-stack/config/homepage/services.yaml
- Media:
    - Plex:
        icon: plex.png
        href: http://localhost:32400/web
        description: Plex Media Server

- Automation:
    - Radarr:
        icon: radarr.png
        href: http://localhost:7878
        description: Movie Automation

    - Sonarr:
        icon: sonarr.png
        href: http://localhost:8989
        description: TV Automation

    - Prowlarr:
        icon: prowlarr.png
        href: http://localhost:9696
        description: Index Manager

- Downloads:
    - SABnzbd:
        icon: sabnzbd.png
        href: http://localhost:8080
        description: Usenet Downloader

- Monitoring:
    - Grafana:
        icon: grafana.png
        href: http://localhost:3001
        description: Metrics Dashboard

    - Prometheus:
        icon: prometheus.png
        href: http://localhost:9090
        description: Metrics Collector
EOF

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "3000:3000"
    volumes:
      - ./config/homepage:/app/config
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