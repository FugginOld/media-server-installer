PLUGIN_NAME="unpackerr"
PLUGIN_DESCRIPTION="Archive extraction"
PLUGIN_CATEGORY="Media Tools"
PLUGIN_DEPENDS=("sabnzbd")

install_service() {

mkdir -p /opt/media-stack/config/unpackerr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 unpackerr:
  image: golift/unpackerr
  container_name: unpackerr
  volumes:
   - ./config/unpackerr:/config
   - /mnt/media/downloads:/downloads
  restart: unless-stopped

EOF

}
