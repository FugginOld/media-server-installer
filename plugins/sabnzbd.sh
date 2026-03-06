PLUGIN_NAME="sabnzbd"
PLUGIN_DESCRIPTION="Usenet downloader"
PLUGIN_CATEGORY="Download Clients"
PLUGIN_DEPENDS=()

install_service() {

mkdir -p /opt/media-stack/config/sabnzbd

cat <<EOF >> /opt/media-stack/docker-compose.yml

 sabnzbd:
  image: lscr.io/linuxserver/sabnzbd
  container_name: sabnzbd
  ports:
   - "8080:8080"
  environment:
   - PUID=1000
   - PGID=1000
  volumes:
   - ./config/sabnzbd:/config
   - /mnt/media/downloads:/downloads
   - /mnt/media/downloads/incomplete:/incomplete-downloads
  restart: unless-stopped

EOF

}
