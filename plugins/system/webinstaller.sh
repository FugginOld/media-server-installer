#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime and libraries
########################################

source "${INSTALL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}/lib/runtime.sh"
source "$LIB_DIR/ports.sh"
source "$LIB_DIR/services.sh"

########################################
# Plugin Metadata
########################################

PLUGIN_NAME="webinstaller"
PLUGIN_DESCRIPTION="Web Landing Page"
PLUGIN_CATEGORY="system"

PLUGIN_DEPENDS=()

PLUGIN_PORT=8088

PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true

########################################
# Install Service
########################################

install_service() {

    log "Installing Web Installer"

########################################
# Register and retrieve port
########################################

    register_port "$PLUGIN_NAME" "$PLUGIN_PORT"
    PORT=$(get_port "$PLUGIN_NAME")

########################################
# Create configuration directory
########################################

    mkdir -p "$CONFIG_DIR/webinstaller"

########################################
# Seed web installer landing page
########################################

cat > "$CONFIG_DIR/webinstaller/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Media Stack Web Installer</title>
  <style>
    :root {
      --bg: #f3f7ff;
      --card: #ffffff;
      --ink: #0f172a;
      --muted: #475569;
      --accent: #0b6bcb;
      --accent-2: #0958a8;
      --ok: #0f9d58;
      --warn: #ef6c00;
      --bad: #d93025;
    }
    body {
      margin: 0;
      font-family: "Segoe UI", "Noto Sans", sans-serif;
      background: radial-gradient(circle at top right, #dbeafe, var(--bg));
      color: var(--ink);
    }
    .wrap {
      max-width: 1080px;
      margin: 30px auto;
      padding: 0 18px;
    }
    .card {
      background: var(--card);
      border-radius: 14px;
      padding: 24px;
      box-shadow: 0 10px 25px rgba(2, 8, 20, 0.08);
    }
    h1 { margin: 0 0 10px; font-size: 2rem; }
    p { margin: 0 0 14px; color: var(--muted); }
    .actions {
      margin-top: 18px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 12px;
    }
    .status-grid {
      margin-top: 18px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
      gap: 12px;
    }
    .status-card {
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 14px;
      background: #fcfdff;
    }
    .status-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }
    .status-name {
      font-weight: 700;
      font-size: 0.95rem;
    }
    .pill {
      border-radius: 999px;
      padding: 4px 10px;
      font-size: 0.75rem;
      font-weight: 700;
      color: #fff;
    }
    .pill.pending { background: #64748b; }
    .pill.ok { background: var(--ok); }
    .pill.warn { background: var(--warn); }
    .pill.bad { background: var(--bad); }
    .meta {
      margin-top: 8px;
      font-size: 0.85rem;
      color: var(--muted);
      word-break: break-all;
    }
    a.btn {
      display: block;
      text-decoration: none;
      background: var(--accent);
      color: #fff;
      padding: 12px 14px;
      border-radius: 10px;
      font-weight: 600;
      text-align: center;
    }
    a.btn:hover { background: var(--accent-2); }
    code {
      display: inline-block;
      background: #eef2ff;
      border-radius: 6px;
      padding: 2px 6px;
    }
    .section-title {
      margin-top: 24px;
      margin-bottom: 6px;
      font-size: 1.1rem;
      font-weight: 700;
    }
    .footer-note {
      margin-top: 18px;
      font-size: 0.9rem;
      color: var(--muted);
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Media Stack Web Installer</h1>
      <p>This web onboarding page runs on top of the same installer pipeline used by the CLI mode.</p>
      <p>You can still choose specific plugins during installation, or use the "ALL" option to deploy everything.</p>

      <div class="section-title">Quick Actions</div>
      <div class="actions">
        <a class="btn" href="http://${HOST_IP}:3001" target="_blank" rel="noopener">Open Homepage</a>
        <a class="btn" href="http://${HOST_IP}:3000" target="_blank" rel="noopener">Open Grafana</a>
        <a class="btn" href="http://${HOST_IP}:${PORT}" target="_blank" rel="noopener">Reload This Dashboard</a>
      </div>

      <div class="section-title">Service Health / Status</div>
      <p>Status checks run from your browser every 20 seconds.</p>
      <div class="status-grid" id="statusGrid"></div>

      <p class="footer-note">CLI fallback command: <code>bash bin/media-stack install</code></p>
    </div>
  </div>

  <script>
    const services = [
      { name: 'Homepage', url: 'http://${HOST_IP}:3001' },
      { name: 'Grafana', url: 'http://${HOST_IP}:3000' },
      { name: 'Prometheus', url: 'http://${HOST_IP}:9090/-/healthy' },
      { name: 'Web Installer', url: 'http://${HOST_IP}:${PORT}' },
      { name: 'Plex', url: 'http://${HOST_IP}:32400/web' },
      { name: 'Overseerr', url: 'http://${HOST_IP}:5055' }
    ];

    const grid = document.getElementById('statusGrid');

    function cardTemplate(service) {
      const card = document.createElement('div');
      card.className = 'status-card';
      card.innerHTML =
        '<div class="status-head">' +
          '<div class="status-name">' + service.name + '</div>' +
          '<div class="pill pending" id="pill-' + service.name.replace(/\s+/g, '-') + '">Checking</div>' +
        '</div>' +
        '<div class="meta">' + service.url + '</div>';
      return card;
    }

    function updatePill(serviceName, cls, text) {
      const id = 'pill-' + serviceName.replace(/\s+/g, '-');
      const pill = document.getElementById(id);
      if (!pill) return;
      pill.className = 'pill ' + cls;
      pill.textContent = text;
    }

    function checkService(service) {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 4000);

      fetch(service.url, { mode: 'no-cors', cache: 'no-store', signal: controller.signal })
        .then(() => updatePill(service.name, 'ok', 'Online'))
        .catch(() => updatePill(service.name, 'bad', 'Offline'))
        .finally(() => clearTimeout(timeout));
    }

    function refreshStatuses() {
      services.forEach(checkService);
    }

    services.forEach(s => grid.appendChild(cardTemplate(s)));
    refreshStatuses();
    setInterval(refreshStatuses, 20000);
  </script>
</body>
</html>
EOF

########################################
# Add container to docker-compose
########################################

cat <<EOF >> "$TMP_COMPOSE"

  webinstaller:
    image: nginx:alpine
    container_name: webinstaller
    ports:
      - "$PORT:$PLUGIN_PORT"
    volumes:
      - ./config/webinstaller:/usr/share/nginx/html
    restart: unless-stopped
EOF

########################################
# Health Check
########################################

cat <<EOF >> "$TMP_COMPOSE"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:$PLUGIN_PORT || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

########################################
# Register service
########################################

    if [[ "$PLUGIN_DASHBOARD" == "true" ]]; then

        register_service \
            "Web Installer" \
            "$PORT" \
            "$PLUGIN_CATEGORY" \
            "webinstaller.png"

    fi

    log "Web Installer installation complete"
}