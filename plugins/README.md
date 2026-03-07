# Media Stack Plugin System

The `plugins/` directory contains all installable services used by the Media Stack.

Each plugin represents a self-contained service that can be installed into the stack.
Plugins dynamically generate Docker Compose services and register themselves with the Media Stack registries.

This architecture allows the stack to be **modular, extensible, and automatically discoverable**.

Plugins are discovered automatically during installation by:

```
installer.sh
```

The installer scans the `plugins/` directory and loads available services.

---

# Plugin Categories

Plugins are organized into subdirectories based on their purpose.

```
plugins/
├── media/
├── automation/
├── download/
├── monitoring/
└── system/
```

Each category contains services related to that function.

---

# Plugin Contract

Every plugin must follow the Media Stack **plugin contract**.

Required metadata fields:

```
PLUGIN_NAME
PLUGIN_DESCRIPTION
PLUGIN_CATEGORY
PLUGIN_DEPENDS
PLUGIN_PORTS
PLUGIN_HOST_NETWORK
PLUGIN_DASHBOARD
```

Example:

```
PLUGIN_NAME="radarr"
PLUGIN_DESCRIPTION="Movie Automation Manager"
PLUGIN_CATEGORY="Automation"
PLUGIN_DEPENDS=(sabnzbd)
PLUGIN_PORTS=(7878)
PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true
```

---

# Required Function

Every plugin must implement:

```
install_service()
```

This function generates the Docker Compose configuration required to run the service.

Example:

```
install_service() {

cat <<EOF >> /opt/media-stack/docker-compose.yml

  radarr:
    image: lscr.io/linuxserver/radarr
    ports:
      - "7878:7878"

EOF

}
```

---

# Port Management

Plugins must request ports using the port helper:

```
scripts/port-helper.sh
```

Example:

```
PORT=$(get_port_mapping "radarr" 7878 7878)
```

This prevents port conflicts between services.

---

# Service Registry

Plugins that expose a web interface should register themselves using:

```
register_service
```

This adds the service to the registry:

```
/opt/media-stack/services.json
```

Example:

```
register_service \
"Radarr" \
"http://localhost:7878" \
"Automation" \
"radarr.png"
```

Registered services appear automatically in:

* Homepage dashboard
* CLI service listings

---

# GPU Support

Plugins that support hardware acceleration can use GPU configuration exported by:

```
core/hardware.sh
```

Example usage:

```
if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi
```

This enables hardware transcoding for services like:

* Plex
* Tdarr

---

# Plugin Discovery

Plugins are automatically discovered by the installer.

Discovery works by scanning for `.sh` files:

```
plugins/**/*.sh
```

This allows new services to be added simply by placing a plugin file in the directory.

No changes to the installer are required.

---

# Adding New Plugins

To add a new service:

1. Create a new plugin file inside the appropriate category.

Example:

```
plugins/media/jellyfin.sh
```

2. Implement the plugin metadata and install function.

3. Run the plugin validator:

```
bash scripts/plugin-validator.sh
```

4. Commit the plugin to the repository.

The installer will automatically detect it.

---

# Plugin Validation

All plugins are validated before installation using:

```
scripts/plugin-validator.sh
```

This ensures plugins contain the required metadata and functions.

If a plugin fails validation, installation will stop.

---

# Summary

The Media Stack plugin system allows the platform to remain modular and extensible.

New services can be added without modifying the installer, making the stack easy to maintain and expand.
