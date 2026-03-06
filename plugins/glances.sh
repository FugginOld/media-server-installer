PLUGIN_NAME="glances"
PLUGIN_DESCRIPTION="System Information"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

cat <<EOF >> /opt/media-stack/docker-compose.yml

 glances:
  image: nicolargo/glances
  container_name: glances
  ports:
   - "61208:61208"
  environment:
   - GLANCES_OPT=-w
  pid: host
  volumes:
   - /var/run/docker.sock:/var/run/docker.sock
  restart: unless-stopped
  healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:61208"]
  interval: 30s
  timeout: 10s
  retries: 5

EOF

}
