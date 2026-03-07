PLUGIN_NAME="watchtower"
PLUGIN_DESCRIPTION="Automatic container updates"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()
PLUGIN_DASHBOARD=false

install_service() {

echo "Installing Watchtower..."

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --schedule "0 0 4 * * *"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","pgrep","watchtower"]
      interval: 60s
      timeout: 10s
      retries: 3

EOF

########################################
# Register service
########################################

#source ./scripts/service-registry.sh

#register_service \
#"Watchtower" \
#"http://localhost" \
#"System" \
#"watchtower.png"

}
