PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Automatic extraction for download clients"
PLUGIN_CATEGORY="Media Tools"
PLUGIN_DEPENDS=("sabnzbd")

install_service() {

mkdir -p /opt/media-stack/config/unpackerr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 unpackerr:
  image: golift/unpackerr
  container_name: unpackerr
  ports:
   - "5656:5656"
  volumes:
   - ./config/unpackerr:/config
   - $DOWNLOAD_PATH:/downloads
  networks:
   - media-network
  restart: unless-stopped
  healthcheck:
   test: ["CMD","wget","--spider","http://localhost:5656/health"]
   interval: 30s
   timeout: 10s
   retries: 3
   start_period: 30s

EOF

}
