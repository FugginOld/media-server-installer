PLUGIN_NAME="watchtower"
PLUGIN_DESCRIPTION="Docker container updater"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

cat <<EOF >> /opt/media-stack/docker-compose.yml

 watchtower:
  image: containrrr/watchtower
  container_name: watchtower
  volumes:
   - /var/run/docker.sock:/var/run/docker.sock
  command: --cleanup --schedule "0 0 4 * * *"
  restart: unless-stopped

EOF

}
