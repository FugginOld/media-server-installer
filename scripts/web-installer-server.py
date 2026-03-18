#!/usr/bin/env python3
import argparse
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def read_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def write_json(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f)
    os.replace(tmp, path)


class Handler(BaseHTTPRequestHandler):
    session_dir = ""
    host_ip = "127.0.0.1"

    def _send_json(self, code, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_html(self, html):
        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        config_defaults_path = os.path.join(self.session_dir, "config-defaults.json")
        config_path = os.path.join(self.session_dir, "config.json")
        plugins_path = os.path.join(self.session_dir, "plugins.json")
        progress_path = os.path.join(self.session_dir, "progress.json")

        if self.path == "/":
            self._send_html(render_html(self.host_ip))
            return

        if self.path == "/api/config":
            defaults = read_json(
                config_defaults_path,
                {
                    "timezone": "UTC",
                    "puid": "1000",
                    "pgid": "1000",
                    "dockerNetwork": "media-network",
                    "dirMode": "default",
                },
            )
            config = read_json(config_path, defaults)
            self._send_json(200, {"defaults": defaults, "config": config, "hasConfig": os.path.exists(config_path)})
            return

        if self.path == "/api/plugins":
            payload = read_json(plugins_path, {"plugins": []})
            self._send_json(200, payload)
            return

        if self.path == "/api/progress":
            payload = read_json(
                progress_path,
                {
                    "phase": "waiting_selection",
                    "message": "Waiting for plugin selection...",
                    "services": [],
                },
            )
            self._send_json(200, payload)
            return

        self._send_json(404, {"error": "not_found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)

        try:
            data = json.loads(raw.decode("utf-8"))
        except Exception:
            self._send_json(400, {"error": "invalid_json"})
            return

        if self.path == "/api/config":
            if not isinstance(data, dict):
                self._send_json(400, {"error": "invalid_config"})
                return

            timezone = str(data.get("timezone", "")).strip()
            puid = str(data.get("puid", "")).strip()
            pgid = str(data.get("pgid", "")).strip()
            docker_network = str(data.get("dockerNetwork", "")).strip()
            dir_mode = str(data.get("dirMode", "default")).strip()

            if not timezone:
                self._send_json(400, {"error": "timezone_required"})
                return
            if not puid.isdigit() or int(puid) > 65535:
                self._send_json(400, {"error": "invalid_puid"})
                return
            if not pgid.isdigit() or int(pgid) > 65535:
                self._send_json(400, {"error": "invalid_pgid"})
                return
            if not docker_network:
                self._send_json(400, {"error": "docker_network_required"})
                return
            if dir_mode not in {"default", "trash"}:
                self._send_json(400, {"error": "invalid_dir_mode"})
                return

            config = {
                "timezone": timezone,
                "puid": puid,
                "pgid": pgid,
                "dockerNetwork": docker_network,
                "dirMode": dir_mode,
            }

            config_path = os.path.join(self.session_dir, "config.json")
            write_json(config_path, config)
            self._send_json(200, {"ok": True})
            return

        if self.path == "/api/select":
            selected = data.get("selected", [])
            all_selected = bool(data.get("all", False))

            if not isinstance(selected, list) or not all(isinstance(x, str) for x in selected):
                self._send_json(400, {"error": "invalid_selected"})
                return

            selection = {
                "all": all_selected,
                "selected": selected,
            }

            selection_path = os.path.join(self.session_dir, "selection.json")
            write_json(selection_path, selection)
            self._send_json(200, {"ok": True})
            return

        self._send_json(404, {"error": "not_found"})


def render_html(host_ip):
  html = """<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Media Stack Web Installer</title>
  <style>
    :root {{
      --bg: #f4f8ff;
      --card: #ffffff;
      --ink: #0f172a;
      --muted: #475569;
      --accent: #0b6bcb;
      --accent2: #0958a8;
      --ok: #0f9d58;
      --run: #ef6c00;
      --wait: #64748b;
      --fail: #d93025;
    }}
    body {{
      margin: 0;
      font-family: Segoe UI, Noto Sans, sans-serif;
      color: var(--ink);
      background: radial-gradient(circle at top right, #dbeafe, var(--bg));
    }}
    .wrap {{ max-width: 980px; margin: 28px auto; padding: 0 16px; }}
    .card {{ background: var(--card); border-radius: 14px; box-shadow: 0 10px 25px rgba(2,8,20,.08); padding: 22px; }}
    h1 {{ margin: 0 0 8px; }}
    h2 {{ margin: 12px 0 6px; font-size: 1.1rem; }}
    .muted {{ color: var(--muted); margin: 0 0 14px; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); gap: 10px; margin-top: 12px; }}
    .plugin {{ border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px; background: #fcfdff; }}
    .plugin label {{ display: block; font-weight: 600; margin-bottom: 6px; }}
    .plugin input, .plugin select {{ width: 100%; box-sizing: border-box; padding: 8px; border: 1px solid #cbd5e1; border-radius: 8px; }}
    .plugin-check label {{ display: flex; align-items: center; gap: 8px; margin: 0; }}
    .category {{ color: var(--muted); font-size: .85rem; margin-top: 6px; }}
    .bar {{ margin-top: 12px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }}
    .btn {{ border: 0; border-radius: 10px; padding: 10px 14px; background: var(--accent); color: #fff; font-weight: 700; cursor: pointer; }}
    .btn:hover {{ background: var(--accent2); }}
    .btn.secondary {{ background: #334155; }}
    .hidden {{ display: none; }}
    .status-grid {{ display: grid; grid-template-columns: repeat(auto-fit,minmax(230px,1fr)); gap: 10px; margin-top: 12px; }}
    .progress-wrap {{ margin-top: 10px; }}
    .progress-meta {{ display: flex; justify-content: space-between; align-items: center; gap: 8px; color: var(--muted); font-size: .9rem; margin-bottom: 6px; }}
    .progress-bar {{ width: 100%; height: 12px; border-radius: 999px; background: #dbe5f2; overflow: hidden; }}
    .progress-fill {{ height: 100%; width: 0%; background: linear-gradient(90deg, #0b6bcb, #10b981); transition: width .25s ease; }}
    .progress-fill.failed {{ background: linear-gradient(90deg, #d93025, #ef6c00); }}
    .progress-active {{ margin-top: 6px; color: var(--muted); font-size: .9rem; }}
    .status-card {{ border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px; background: #fcfdff; }}
    .head {{ display: flex; justify-content: space-between; align-items: center; gap: 8px; }}
    .pill {{ border-radius: 999px; color: #fff; font-size: .75rem; font-weight: 700; padding: 3px 10px; }}
    .pending {{ background: var(--wait); }}
    .in_progress {{ background: var(--run); }}
    .done {{ background: var(--ok); }}
    .failed {{ background: var(--fail); }}
    .note {{ color: var(--muted); font-size: .85rem; margin-top: 6px; }}
    .links {{ margin-top: 16px; color: var(--muted); font-size: .9rem; }}
    code {{ background: #eef2ff; border-radius: 6px; padding: 2px 6px; }}
  </style>
</head>
<body>
  <div class=\"wrap\"> 
    <div class=\"card\"> 
      <h1>Media Stack Web Installer</h1>
      <p class=\"muted\">Configure the stack, choose plugins, then monitor installation progress.</p>

      <section id=\"configSection\">
        <h2>Installer Configuration</h2>
        <div class=\"grid\">
          <div class=\"plugin\"><label for=\"cfgTimezone\">Timezone</label><input id=\"cfgTimezone\"></div>
          <div class=\"plugin\"><label for=\"cfgPuid\">PUID</label><input id=\"cfgPuid\" type=\"number\" min=\"0\" max=\"65535\"></div>
          <div class=\"plugin\"><label for=\"cfgPgid\">PGID</label><input id=\"cfgPgid\" type=\"number\" min=\"0\" max=\"65535\"></div>
          <div class=\"plugin\"><label for=\"cfgNetwork\">Docker Network Name</label><input id=\"cfgNetwork\"></div>
          <div class=\"plugin\"><label for=\"cfgDirMode\">Directory Structure</label>
            <select id=\"cfgDirMode\"><option value=\"default\">Default</option><option value=\"trash\">Trash Guides</option></select>
          </div>
        </div>
        <div class=\"bar\">
          <button class=\"btn\" id=\"saveConfig\" type=\"button\">Save Configuration</button>
          <span id=\"configMsg\" class=\"muted\" style=\"margin:0\"></span>
        </div>
      </section>

      <section id=\"selection\">
        <h2>Plugin Selection</h2>
        <div class=\"bar\">
          <button class=\"btn secondary\" id=\"selectAll\" type=\"button\">Select All</button>
          <button class=\"btn\" id=\"startInstall\" type=\"button\">Start Installation</button>
        </div>
        <div class=\"grid\" id=\"pluginGrid\"></div>
      </section>

      <section id=\"progress\" class=\"hidden\">
        <h2>Install Progress</h2>
        <p id=\"phase\" class=\"muted\">Waiting...</p>
        <div class=\"progress-wrap\">
          <div class=\"progress-meta\">
            <span id=\"progressSummary\">0/0 complete</span>
            <strong id=\"progressPct\">0%</strong>
          </div>
          <div class=\"progress-bar\"><div class=\"progress-fill\" id=\"progressFill\"></div></div>
          <div class=\"progress-active\" id=\"progressActive\">Currently installing: waiting for tasks...</div>
        </div>
        <div class=\"status-grid\" id=\"statusGrid\"></div>
        <div class=\"links\">After install: <a href=\"http://__HOST_IP__:3001\" target=\"_blank\">Homepage</a> | <a href=\"http://__HOST_IP__:3000\" target=\"_blank\">Grafana</a></div>
      </section>

      <p class=\"links\">CLI fallback: <code>bash bin/media-stack install</code></p>
    </div>
  </div>

  <script>
    const cfgTimezone = document.getElementById('cfgTimezone');
    const cfgPuid = document.getElementById('cfgPuid');
    const cfgPgid = document.getElementById('cfgPgid');
    const cfgNetwork = document.getElementById('cfgNetwork');
    const cfgDirMode = document.getElementById('cfgDirMode');
    const cfgMsg = document.getElementById('configMsg');
    const pluginGrid = document.getElementById('pluginGrid');
    const statusGrid = document.getElementById('statusGrid');
    const phase = document.getElementById('phase');
    const progressFill = document.getElementById('progressFill');
    const progressPct = document.getElementById('progressPct');
    const progressSummary = document.getElementById('progressSummary');
    const progressActive = document.getElementById('progressActive');
    const selectionSection = document.getElementById('selection');
    const progressSection = document.getElementById('progress');

    let plugins = [];
    let poller = null;

    function renderPlugins() {
      pluginGrid.innerHTML = '';
      for (const p of plugins) {
        const id = 'plg-' + p.name;
        const card = document.createElement('div');
        card.className = 'plugin plugin-check';
        card.innerHTML = `
          <label><input type=\"checkbox\" id=\"${id}\" ${p.defaultSelected ? 'checked' : ''}> ${p.name}</label>
          <div class=\"category\">Category: ${p.category || 'general'}</div>
        `;
        pluginGrid.appendChild(card);
      }
    }

    function selectedPlugins() {
      return plugins
        .map(p => ({ name: p.name, checked: document.getElementById('plg-' + p.name)?.checked }))
        .filter(x => x.checked)
        .map(x => x.name);
    }

    function setAll(state) {
      for (const p of plugins) {
        const el = document.getElementById('plg-' + p.name);
        if (el) el.checked = state;
      }
    }

    async function saveConfig() {
      const payload = {
        timezone: (cfgTimezone.value || '').trim(),
        puid: String(cfgPuid.value || '').trim(),
        pgid: String(cfgPgid.value || '').trim(),
        dockerNetwork: (cfgNetwork.value || '').trim(),
        dirMode: cfgDirMode.value || 'default'
      };

      const res = await fetch('/api/config', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'unknown' }));
        throw new Error(err.error || 'config_save_failed');
      }

      cfgMsg.textContent = 'Configuration saved.';
    }

    function renderProgress(payload) {
      phase.textContent = payload.message || payload.phase || 'Installing...';
      statusGrid.innerHTML = '';
      const services = payload.services || [];
      const statusPriority = { failed: 0, in_progress: 1, pending: 2, done: 3 };
      const sortedServices = [...services].sort((a, b) => {
        const pa = statusPriority[a.status] ?? 99;
        const pb = statusPriority[b.status] ?? 99;
        if (pa !== pb) return pa - pb;
        return (a.name || '').localeCompare(b.name || '');
      });

      const total = services.length;
      const done = services.filter(s => s.status === 'done').length;
      const failed = services.filter(s => s.status === 'failed').length;
      const pct = total > 0 ? Math.round(((done + failed) / total) * 100) : 0;
      const active = services.filter(s => s.status === 'in_progress').map(s => s.name);

      progressFill.style.width = pct + '%';
      if (failed > 0) {
        progressFill.classList.add('failed');
      } else {
        progressFill.classList.remove('failed');
      }
      progressPct.textContent = pct + '%';
      progressSummary.textContent = `${done} done / ${failed} failed / ${total} total`;
      if (active.length > 0) {
        progressActive.textContent = `Currently installing: ${active.join(', ')}`;
      } else if ((payload.phase || '') === 'completed') {
        progressActive.textContent = 'Currently installing: complete';
      } else if (failed > 0) {
        progressActive.textContent = 'Currently installing: halted due to error';
      } else {
        progressActive.textContent = 'Currently installing: waiting for next step...';
      }

      for (const svc of sortedServices) {
        const status = svc.status || 'pending';
        const note = svc.note || '';
        const card = document.createElement('div');
        card.className = 'status-card';
        card.innerHTML = `
          <div class=\"head\">
            <strong>${svc.name}</strong>
            <span class=\"pill ${status}\">${status.replace('_', ' ')}</span>
          </div>
          <div class=\"note\">${note}</div>
        `;
        statusGrid.appendChild(card);
      }
    }

    async function fetchProgress() {
      const r = await fetch('/api/progress', { cache: 'no-store' });
      const data = await r.json();
      renderProgress(data);
      if (data.phase === 'completed' || data.phase === 'failed') {
        if (poller) clearInterval(poller);
      }
    }

    async function init() {
      const c = await fetch('/api/config', { cache: 'no-store' });
      const cData = await c.json();
      const cfg = cData.config || cData.defaults || {};
      cfgTimezone.value = cfg.timezone || 'UTC';
      cfgPuid.value = cfg.puid || '1000';
      cfgPgid.value = cfg.pgid || '1000';
      cfgNetwork.value = cfg.dockerNetwork || 'media-network';
      cfgDirMode.value = cfg.dirMode || 'default';

      const r = await fetch('/api/plugins', { cache: 'no-store' });
      const data = await r.json();
      plugins = data.plugins || [];
      renderPlugins();

      if (plugins.length === 0) {
        selectionSection.classList.add('hidden');
      }

      document.getElementById('saveConfig').addEventListener('click', async () => {
        cfgMsg.textContent = 'Saving...';
        try {
          await saveConfig();
          if (plugins.length === 0) {
            cfgMsg.textContent = 'Configuration saved. Return to the installer terminal.';
          }
        } catch (e) {
          cfgMsg.textContent = 'Failed to save configuration: ' + e.message;
        }
      });

      if (plugins.length > 0) {
        document.getElementById('selectAll').addEventListener('click', () => setAll(true));

        document.getElementById('startInstall').addEventListener('click', async () => {
          cfgMsg.textContent = 'Saving...';
          try {
            await saveConfig();
          } catch (e) {
            cfgMsg.textContent = 'Failed to save configuration: ' + e.message;
            return;
          }

          const selected = selectedPlugins();
          const all = selected.length === plugins.length;
          if (selected.length === 0) {
            alert('Select at least one plugin.');
            return;
          }

          const res = await fetch('/api/select', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ selected, all })
          });

          if (!res.ok) {
            alert('Failed to submit selection.');
            return;
          }

          selectionSection.classList.add('hidden');
          progressSection.classList.remove('hidden');
          await fetchProgress();
          poller = setInterval(fetchProgress, 2000);
        });
      }
    }

    init();
  </script>
</body>
</html>
"""
  return html.replace("__HOST_IP__", host_ip)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--session-dir", required=True)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8099)
    parser.add_argument("--host-ip", default="127.0.0.1")
    args = parser.parse_args()

    os.makedirs(args.session_dir, exist_ok=True)

    Handler.session_dir = args.session_dir
    Handler.host_ip = args.host_ip

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
