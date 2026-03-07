PLUGIN_NAME="homepage"
PLUGIN_DESCRIPTION="Service dashboard"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()
PLUGIN_DASHBOARD=true

install_service() {

echo "Installing Homepage dashboard..."

########################################
# Create config directory
########################################

mkdir -p /opt/media-stack/config/homepage

########################################
# Generate services dashboard
########################################

source ./scripts/service-registry.sh

SERVICES=$(list_services)

echo "Generating Homepage dashboard..."

echo "$SERVICES" | jq -r '
.services
| group_by(.category)
| .[]
| "- \(.[0].category):"
  + ( .[]
      | "\n    - \(.name):\n        icon: \(.icon)\n        href: \(.url)"
    )
' > /opt/media-stack/config/homepage/services.yaml

########################################
# Add container
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - "3000:3000"
    volumes:
      - ./config/homepage:/app/config
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

register_service \
"Homepage" \
"http://localhost:3000" \
"System" \
"homepage.png"

}
