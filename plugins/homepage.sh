PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Media server dashboard"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/homepage

cat <<EOF >> /opt/media-stack/docker-compose.yml

 homepage:
  image: ghcr.io/gethomepage/homepage:latest
  container_name: homepage
  ports:
   - "3000:3000"
  volumes:
   - ./config/homepage:/app/config
   - /var/run/docker.sock:/var/run/docker.sock
  restart: unless-stopped
  healthcheck:
   test: ["CMD", "curl", "-f", "http://localhost:3000"]
   interval: 30s
   timeout: 10s
   retries: 5

EOF

}
