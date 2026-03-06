PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Browser-based installer interface"
PLUGIN_CATEGORY="System"
PLUGIN_DEPENDS=()

install_service() {

echo "Installing Web Installer..."

mkdir -p /opt/media-stack/webinstaller
mkdir -p /opt/media-stack/webinstaller/templates

########################################
# Create Flask backend
########################################

cat <<'EOF' > /opt/media-stack/webinstaller/app.py
from flask import Flask, render_template, request
from flask_socketio import SocketIO
import subprocess

app = Flask(__name__)
socketio = SocketIO(app)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/install", methods=["POST"])
def install():

    platform = request.form.get("platform")
    layout = request.form.get("layout")
    services = request.form.getlist("services")

    cmd = ["bash","/installer/installer.sh",platform,layout] + services

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    for line in process.stdout:
        socketio.emit("log", {"data": line})

    return "Installation started"

@socketio.on("connect")
def connected():
    print("Client connected")

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=8080)
EOF

########################################
# Create Web UI
########################################

cat <<'EOF' > /opt/media-stack/webinstaller/templates/index.html
<!DOCTYPE html>
<html>

<head>
<title>Media Stack Installer</title>
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
</head>

<body>

<h1>Media Server Setup</h1>

<form id="installForm">

Platform
<select name="platform">
<option value="baremetal">Baremetal</option>
<option value="unraid">Unraid</option>
<option value="truenas">TrueNAS</option>
</select>

<br><br>

Directory Layout
<select name="layout">
<option value="default">Default</option>
<option value="trash">TRaSH</option>
</select>

<br><br>

Services
<input type="checkbox" name="services" value="plex"> Plex
<input type="checkbox" name="services" value="radarr"> Radarr
<input type="checkbox" name="services" value="sonarr"> Sonarr
<input type="checkbox" name="services" value="sabnzbd"> SABnzbd
<input type="checkbox" name="services" value="prowlarr"> Prowlarr

<br><br>

<button type="submit">Install</button>

</form>

<h2>Installer Output</h2>
<pre id="logs"></pre>

<script>

const socket = io();

socket.on("log", function(msg) {
    document.getElementById("logs").innerHTML += msg.data;
});

document.getElementById("installForm").onsubmit = async function(e){

    e.preventDefault();

    const formData = new FormData(this);

    await fetch("/install", {
        method: "POST",
        body: formData
    });

}

</script>

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
    command: bash -c "pip install flask flask-socketio eventlet && python app.py"
    restart: unless-stopped
    networks:
      - media-network

    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5

EOF

}