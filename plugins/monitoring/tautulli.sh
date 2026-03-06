PLUGIN_NAME="tautulli"
PLUGIN_DESCRIPTION="Plex monitoring and analytics"
PLUGIN_CATEGORY="Monitoring"
PLUGIN_DEPENDS=("plex")

install_service() {

echo "Installing Tautulli..."

mkdir -p /opt/media-stack/config/tautulli
mkdir -p /opt/media-stack/config/tautulli/geoip

########################################
# Download GeoIP database
########################################

echo "Downloading GeoIP database..."

curl -L \
https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
-o /tmp/geoip.tar.gz

tar -xzf /tmp/geoip.tar.gz -C /opt/media-stack/config/tautulli/geoip --strip-components=1

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  tautulli:
    image: lscr.io/linuxserver/tautulli
    container_name: tautulli
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/tautulli:/config
    ports:
      - "8181:8181"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8181"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}