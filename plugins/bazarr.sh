PLUGIN_NAME="bazarr"
PLUGIN_DESCRIPTION="Subtitle automation"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=("sonarr" "radarr")

install_service() {

mkdir -p /opt/media-stack/config/bazarr

cat <<EOF >> /opt/media-stack/docker-compose.yml

 bazarr:
  image: lscr.io/linuxserver/bazarr
  container_name: bazarr
  ports:
   - "6767:6767"
  environment:
   - PUID=1000
   - PGID=1000
  volumes:
   - ./config/bazarr:/config
   - /mnt/media/movies:/movies
   - /mnt/media/tv:/tv
  restart: unless-stopped

EOF

}
