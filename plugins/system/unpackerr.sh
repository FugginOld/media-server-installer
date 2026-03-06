PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Automatic archive extraction"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=("radarr" "sonarr" "sabnzbd")

install_service() {

echo "Installing Unpackerr..."

mkdir -p /opt/media-stack/config/unpackerr

cat <<EOF >> /opt/media-stack/docker-compose.yml

  unpackerr:
    image: golift/unpackerr
    container_name: unpackerr
    environment:
      - TZ=UTC
      - UNPACKERR_DEBUG=false
    volumes:
      - ./config/unpackerr:/config
      - $DOWNLOADS_PATH:/downloads
    ports:
      - "5656:5656"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:5656/health"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}
