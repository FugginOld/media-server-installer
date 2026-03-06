PLUGIN_NAME="plex"
PLUGIN_DESCRIPTION="Plex Media Server"
PLUGIN_CATEGORY="Media Servers"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/plex

cat <<EOF >> /opt/media-stack/docker-compose.yml

 plex:
  image: lscr.io/linuxserver/plex
  container_name: plex
  network_mode: host
EOF

if [ "$GPU_TYPE" != "none" ]; then
echo "  $GPU_DEVICES" >> /opt/media-stack/docker-compose.yml
fi

cat <<EOF >> /opt/media-stack/docker-compose.yml
  volumes:
   - ./config/plex:/config
   - /mnt/media:/media
  restart: unless-stopped
  healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:32400"]
  interval: 30s
  timeout: 10s
  retries: 5

EOF

}
