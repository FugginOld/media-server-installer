PLUGIN_NAME="tailscale"
PLUGIN_DESCRIPTION="Mesh VPN service"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/tailscale

cat <<EOF >> /opt/media-stack/docker-compose.yml

 tailscale:
  image: tailscale/tailscale
  container_name: tailscale
  network_mode: host
  cap_add:
   - NET_ADMIN
  volumes:
   - ./config/tailscale:/var/lib/tailscale
  restart: unless-stopped

EOF

}
