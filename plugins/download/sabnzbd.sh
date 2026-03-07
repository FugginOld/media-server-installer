PLUGIN_NAME="sabnzbd"
PLUGIN_DESCRIPTION="Usenet downloader"
PLUGIN_CATEGORY="Download"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing SABnzbd..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/sabnzbd

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd
    container_name: sabnzbd
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/sabnzbd:/config
      - $DOWNLOADS_PATH:/downloads
EOF

########################################
# TRaSH layout support
########################################

if [ "$DIR_LAYOUT" = "trash" ]; then

cat <<EOF >> /opt/media-stack/docker-compose.yml
      - $INCOMPLETE_PATH:/incomplete
EOF

fi

########################################
# Continue container config
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml
    ports:
      - "8080:8080"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","curl","-f","http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"SABnzbd" \
"http://localhost:8080" \
"Download" \
"sabnzbd.png"

}