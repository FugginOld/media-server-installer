PLUGIN_NAME="tailscale"
PLUGIN_DESCRIPTION="Secure mesh VPN"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/tailscale

cat <<EOF >> /opt/media-stack/docker-compose.yml

 tailscale:
  image: tailscale/tailscale
  container_name: tailscale
  hostname: media-server
  volumes:
   - ./config/tailscale:/var/lib/tailscale
   - /dev/net/tun:/dev/net/tun
  cap_add:
   - NET_ADMIN
   - SYS_MODULE
  networks:
   - media-network
  restart: unless-stopped
  healthcheck:
   test: ["CMD","tailscale","status"]
   interval: 60s
   timeout: 10s
   retries: 3

EOF

}
