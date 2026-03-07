PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Automatic archive extraction"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=("radarr" "sonarr" "sabnzbd")
PLUGIN_DASHBOARD=false

install_service() {

echo "Installing Unpackerr..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/unpackerr

########################################
# Add container
########################################

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
# Continue container configuration
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml
    ports:
      - "5656:5656"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:5656/health"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

#source ./scripts/service-registry.sh

#register_service \
#"Unpackerr" \
#"http://localhost:5656" \
#"System" \
#"unpackerr.png"

}
