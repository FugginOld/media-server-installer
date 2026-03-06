PLUGIN_NAME="radarr"
PLUGIN_DESCRIPTION="Movie automation"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sabnzbd")

install_service() {

mkdir -p /opt/media-stack/config/radarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 radarr:
  image: lscr.io/linuxserver/radarr
  container_name: radarr
  ports:
   - "7878:7878"
  environment:
   - PUID=1000
   - PGID=1000
  volumes:
   - ./config/radarr:/config
   - /mnt/media/movies:/movies
   - /mnt/media/downloads:/downloads
  restart: unless-stopped

EOF

}
