PLUGIN_NAME="sonarr"
PLUGIN_DESCRIPTION="TV automation"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")

install_service() {

mkdir -p /opt/media-stack/config/sonarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 sonarr:
  image: lscr.io/linuxserver/sonarr
  container_name: sonarr
  ports:
   - "8989:8989"
  environment:
   - PUID=1000
   - PGID=1000
  volumes:
   - ./config/sonarr:/config
   - /mnt/media/tv:/tv
   - /mnt/media/downloads:/downloads
  restart: unless-stopped

EOF

}
