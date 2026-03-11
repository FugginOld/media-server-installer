# Media Stack Plugin Development Guide

This guide explains how to create new plugins for the Media Stack platform.

Plugins allow developers to add new services to the stack without modifying the installer.

---

# Plugin Structure

Plugins are located in the `plugins/` directory.

Example:

```
plugins/media/jellyfin.sh
```

Each plugin is a shell script that follows the Media Stack plugin contract.

---

# Plugin Metadata

Every plugin must define the following metadata fields.

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
PLUGIN_NAME="jellyfin"
PLUGIN_DESCRIPTION="Open source media server"
PLUGIN_CATEGORY="Media"
PLUGIN_DEPENDS=()
PLUGIN_PORTS=(8096)
PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true
```

---

# Required Function

Plugins must implement the function:

```
install_service()
```

This function generates the Docker Compose configuration for the service.

Example:

```
install_service() {

cat <<EOF >> /opt/media-stack/docker-compose.yml

  jellyfin:
    image: jellyfin/jellyfin
    ports:
      - "8096:8096"
    restart: unless-stopped

EOF

}
```

---

# Port Allocation

Plugins must request ports using the port helper system.

Example:

```
PORT=$(get_port_mapping "jellyfin" 8096 8096)
```

This prevents port conflicts between services.

---

# Service Registration

Plugins that provide web interfaces should register themselves.

Example:

```
register_service \
"Jellyfin" \
"http://localhost:8096" \
"Media" \
"jellyfin.png"
```

Registered services appear in:

- Homepage dashboard
- CLI service list

---

# Dependency Management

Plugins can declare dependencies.

Example:

```
PLUGIN_DEPENDS=(radarr sonarr)
```

The installer automatically installs dependencies when required.

---

# GPU Support

Plugins can support GPU acceleration by using hardware configuration exported by:

```
core/hardware.sh
```

Example:

```
if [ "$GPU_TYPE" != "none" ]; then
echo "$GPU_DEVICES" >> "$STACK_DIR/docker-compose.yml"
fi
```

---

# Plugin Validation

Before committing plugins, validate them using:

```
bash scripts/plugin-validator.sh
```

This ensures the plugin follows the required structure.

---

# Best Practices

Recommended practices for plugin development:

- use official container images when possible
- avoid hardcoding ports
- store configuration under `/opt/media-stack/config`
- include health checks
- register dashboard services

---

# Example Plugin

```
plugins/media/example.sh
```

```
PLUGIN_NAME="example"
PLUGIN_DESCRIPTION="Example service"
PLUGIN_CATEGORY="Media"
PLUGIN_DEPENDS=()
PLUGIN_PORTS=(1234)
PLUGIN_HOST_NETWORK=false
PLUGIN_DASHBOARD=true
```

---

# Summary

The plugin system allows the Media Stack platform to be easily extended with new services.

Developers can add new functionality simply by creating a plugin script that follows the plugin contract.