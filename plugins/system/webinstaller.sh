PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Browser-based installer interface"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Web Installer..."

########################################
# Create directories
########################################

mkdir -p /opt/media-stack/webinstaller
mkdir -p /opt/media-stack/webinstaller/templates

########################################
# Flask backend
########################################

cat <<'EOF' > /opt/media-stack/webinstaller/app.py
from flask import Flask, render_template, request
import subprocess

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/install", methods=["POST"])
def install():

    services = request.form.getlist("services")

    cmd = ["bash", "/installer/installer.sh"] + services

    subprocess.Popen(cmd)

    return "Installation started"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
EOF

########################################
# Web UI
########################################

cat <<'EOF' > /opt/media-stack/webinstaller/templates/index.html
<!DOCTYPE html>
<html>
<head>
<title>Media Stack Installer</title>
</head>

<body>

<h1>Media Server Installer</h1>

<form method="post" action="/install">

<h3>Select Services</h3>

<input type="checkbox" name="services" value="plex"> Plex<br>
<input type="checkbox" name="services" value="radarr"> Radarr<br>
<input type="checkbox" name="services" value="sonarr"> Sonarr<br>
<input type="checkbox" name="services" value="sabnzbd"> SABnzbd<br>
<input type="checkbox" name="services" value="prowlarr"> Prowlarr<br>
<input type="checkbox" name="services" value="bazarr"> Bazarr<br>

<br>
<button type="submit">Install</button>

</form>

</body>
</html>
EOF

########################################
# Add container to stack
########################################

cat <<EOF >> /opt/media-stack/docker-compose.yml

  webinstaller:
    image: python:3.11-slim
    container_name: webinstaller
    ports:
      - "8088:8080"
    volumes:
      - /opt/media-server-installer:/installer
      - ./webinstaller:/app
    working_dir: /app
    command: bash -c "pip install flask && python app.py"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD","wget","--spider","http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

########################################
# Register service
########################################

source ./scripts/service-registry.sh

register_service \
"Web Installer" \
"http://localhost:8088" \
"System" \
"webinstaller.png"

}