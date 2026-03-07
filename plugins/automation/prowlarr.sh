PLUGIN_NAME="prowlarr"
PLUGIN_DESCRIPTION="Indexer manager"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("radarr" "sonarr")
PLUGIN_DASHBOARD=true

install_service() {

echo "Installing Prowlarr..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/prowlarr

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  prowlarr:
    image: lscr.io/linuxserver/prowlarr
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/prowlarr:/config
    ports:
      - "9696:9696"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","curl","-f","http://localhost:9696/api/v1/system/status"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Prowlarr" \
"http://localhost:9696" \
"Automation" \
"prowlarr.png"

}
