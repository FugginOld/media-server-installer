PLUGIN_NAME="overseerr"
PLUGIN_DESCRIPTION="Request media automation"
PLUGIN_CATEGORY="Requests"
PLUGIN_DEPENDS=("plex")

install_service() {

mkdir -p /opt/media-stack/config/overseerr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 overseerr:
  image: sctx/overseerr
  container_name: overseerr
  ports:
   - "5055:5055"
  volumes:
   - ./config/overseerr:/app/config
  restart: unless-stopped
  healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5055"]
  interval: 30s
  timeout: 10s
  retries: 5

EOF

}
