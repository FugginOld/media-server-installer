PLUGIN_NAME="tdarr"
PLUGIN_DESCRIPTION="Transcoding automation"
PLUGIN_CATEGORY="Media Tools"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/tdarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 tdarr:
  image: ghcr.io/haveagitgat/tdarr
  container_name: tdarr
  ports:
   - "8265:8265"
   - "8266:8266"
EOF

if [ "$GPU_TYPE" != "none" ]; then
echo "  $GPU_DEVICES" >> /opt/media-stack/docker-compose.yml
fi

cat <<EOF >> /opt/media-stack/docker-compose.yml
  volumes:
   - ./config/tdarr:/app/config
   - /mnt/media:/media
  restart: unless-stopped
  healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8265"]
  interval: 30s
  timeout: 10s
  retries: 5

EOF

}
