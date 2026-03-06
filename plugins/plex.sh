PLUGIN_NAME="plex"
PLUGIN_DESCRIPTION="Plex Media Server"
PLUGIN_CATEGORY="Media"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Plex Media Server..."

mkdir -p /opt/media-stack/config/plex

cat <<EOF >> /opt/media-stack/docker-compose.yml

  plex:
    image: lscr.io/linuxserver/plex
    container_name: plex
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=UTC
    volumes:
      - ./config/plex:/config
      - $MOVIES_PATH:/movies
      - $TV_PATH:/tv
      - $MEDIA_PATH:/media
    restart: unless-stopped
EOF

########################################
# Add GPU support if detected
########################################

if [ "$GPU_TYPE" != "none" ]; then

echo "$GPU_DEVICES" >> /opt/media-stack/docker-compose.yml

fi

########################################
# Add health check
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:32400/web/index.html"]
      interval: 30s
      timeout: 10s
      retries: 5

    networks:
      - media-network

EOF

}
