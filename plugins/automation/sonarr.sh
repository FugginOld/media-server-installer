PLUGIN_NAME="sonarr"
PLUGIN_DESCRIPTION="TV automation"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")

install_service() {

mkdir -p /opt/media-stack/config/sonarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

  sonarr:
    image: lscr.io/linuxserver/sonarr
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./config/sonarr:/config
      - $TV_PATH:/tv
      - $DOWNLOADS_PATH:/downloads
    ports:
      - "8989:8989"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","curl","-f","http://localhost:8989/api/v3/system/status"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

source ./scripts/service-registry.sh

register_service \
"Sonarr" \
"http://localhost:8989" \
"Automation" \
"sonarr.png"

}