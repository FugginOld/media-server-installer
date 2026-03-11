# Media Stack Plugin System

The `plugins/` directory contains all installable services used by the Media Stack.

Each plugin represents a self-contained service that can be installed into the stack.  
Plugins dynamically generate Docker Compose services and register themselves with the Media Stack registries.

This architecture allows the stack to be modular, extensible, and automatically discoverable.

Plugins are detected automatically during installation by the installer.

---

# Plugin Directory Structure

Plugins are organized by category.

```
plugins/
├── media
├── automation
├── download
├── monitoring
└── system
```

Each folder groups services with similar roles.

---

# Plugin Contract

Every plugin must follow the Media Stack plugin contract.

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

Example plugin metadata:

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

Every plugin must implement the function:

```
install_service()
```

This function is responsible for adding the container configuration to the Docker Compose stack.

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

Plugins must not hardcode ports directly.

Ports are requested using the port helper:

```
scripts/port-helper.sh
```

Example usage:

```
PORT=$(get_port_mapping "radarr" 7878 7878)
```

The port registry ensures that multiple plugins do not attempt to use the same port.

Port registry file:

```
/opt/media-stack/ports.json
```

---

# Service Registration

Plugins that expose web interfaces should register themselves using:

```
register_service
```

Example:

```
register_service \
"Radarr" \
"http://localhost:7878" \
"Automation" \
"radarr.png"
```

Registered services are stored in:

```
/opt/media-stack/services.json
```

The service registry powers:

- the Homepage dashboard
- the CLI `media-stack services` command
- monitoring integrations

---

# Dependency Management

Plugins can declare dependencies using:

```
PLUGIN_DEPENDS
```

Example:

```
PLUGIN_DEPENDS=(radarr sonarr)
```

If a user installs a plugin that requires dependencies, the installer automatically installs the required services.

Example dependency chain:

```
Overseerr
  ├─ Radarr
  └─ Sonarr
```

---

# GPU Hardware Support

Plugins that support hardware acceleration can use GPU configuration exported by:

```
core/hardware.sh
```

Supported GPU types:

- Intel QuickSync
- AMD VAAPI
- NVIDIA NVENC

Example usage inside a plugin:

```
if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi
```

This allows services such as Plex and Tdarr to enable hardware transcoding automatically.

---

# Cross Platform Compatibility

Plugins are designed to run on multiple Linux distributions.

The installer supports:

Debian-based systems
- Debian
- Ubuntu
- Devuan
- Linux Mint

RedHat-based systems
- Fedora
- Rocky Linux
- AlmaLinux

Arch-based systems
- Arch Linux
- Manjaro

SUSE systems
- openSUSE

Lightweight systems
- Alpine Linux

The platform abstraction layer ensures plugins work consistently across these environments.

---

# NAS Platform Compatibility

The installer automatically detects NAS environments and applies container permission fixes.

Supported NAS platforms include:

- Unraid
- TrueNAS SCALE
- OpenMediaVault
- CasaOS

This ensures that containers can access shared storage correctly.

---

# Plugin Discovery

Plugins are automatically discovered during installation.

The installer scans the plugins directory for `.sh` files:

```
plugins/**/*.sh
```

Any valid plugin placed in this directory will automatically appear in the installer menu.

No modifications to the installer are required.

---

# Creating New Plugins

To add a new service:

1. Create a plugin script inside the appropriate category directory.

Example:

```
plugins/media/jellyfin.sh
```

2. Implement the required metadata fields.

3. Implement the `install_service()` function.

4. Validate the plugin:

```
bash scripts/plugin-validator.sh
```

5. Commit the plugin to the repository.

The installer will automatically detect it.

---

# Summary

The Media Stack plugin system allows the platform to remain modular and extensible.

Plugins can be added, removed, or modified without changing the installer.

This design allows the Media Stack to grow over time while keeping the core installer simple and maintainable.