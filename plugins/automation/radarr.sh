PLUGIN_NAME="radarr"
PLUGIN_DESCRIPTION="Movie automation service"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")
PLUGIN_DASHBOARD=true

install_service() {

echo "Installing Radarr..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/radarr

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  radarr:
    image: lscr.io/linuxserver/radarr
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/radarr:/config
      - $MOVIES_PATH:/movies
      - $DOWNLOADS_PATH:/downloads
    ports:
      - "7878:7878"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","curl","-f","http://localhost:7878/api/v3/system/status"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Radarr" \
"http://localhost:7878" \
"Automation" \
"radarr.png"

}
