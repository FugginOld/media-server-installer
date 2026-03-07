PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle automation service"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("radarr" "sonarr")

install_service() {

echo "Installing Bazarr..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/bazarr

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  bazarr:
    image: lscr.io/linuxserver/bazarr
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/bazarr:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
    ports:
      - "6767:6767"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","curl","-f","http://localhost:6767"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Bazarr" \
"http://localhost:6767" \
"Automation" \
"bazarr.png"

}