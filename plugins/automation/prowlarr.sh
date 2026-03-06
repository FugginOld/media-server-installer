PLUGIN_NAME="prowlarr"
PLUGIN_DESCRIPTION="Indexer automation"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/prowlarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 prowlarr:
  image: lscr.io/linuxserver/prowlarr
  container_name: prowlarr
  ports:
   - "9696:9696"
  environment:
   - PUID=1000
   - PGID=1000
  volumes:
   - ./config/prowlarr:/config
  restart: unless-stopped
  healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9696"]
  interval: 30s
  timeout: 10s
  retries: 5

EOF

}
