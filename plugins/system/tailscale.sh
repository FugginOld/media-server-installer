PLUGIN_NAME="tailscale"
PLUGIN_DESCRIPTION="Secure mesh VPN remote access"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()
PLUGIN_DASHBOARD=false

install_service() {

echo "Installing Tailscale..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/tailscale

########################################
# Add container to docker-compose
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: media-server
    environment:
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_AUTHKEY=
    volumes:
      - ./config/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","tailscale","status"]
      interval: 60s
      timeout: 10s
      retries: 3

EOF

########################################
# Register service
########################################

#source ./scripts/service-registry.sh

#register_service \
#"Tailscale" \
#"http://localhost" \
#"System" \
#"tailscale.png"

}
