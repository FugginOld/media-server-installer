# Media Stack Operational Scripts

The `scripts/` directory contains the operational tools used by the Media Stack installer and runtime environment.

These scripts provide management functionality such as:

* Docker container lifecycle management
* service and port registries
* plugin validation
* backups and updates
* monitoring automation
* system diagnostics
* CLI management commands

Many of these scripts are called automatically by:

```
installer.sh
```

while others are used through the Media Stack CLI tool:

```
media-stack
```

---

# Script Overview

## compose.sh

Controls the Docker Compose stack lifecycle.

This script is used by the CLI and installer to start, stop, and manage containers.

Supported commands:

```
compose.sh up
compose.sh down
compose.sh restart
compose.sh pull
compose.sh logs
compose.sh status
```

Example:

```
bash scripts/compose.sh up
```

---

## service-registry.sh

Maintains the **service registry** used by dashboards and CLI tools.

The registry file is stored at:

```
/opt/media-stack/services.json
```

Plugins register themselves during installation using:

```
register_service
```

The registry allows:

* Homepage dashboard auto-discovery
* CLI service listing
* monitoring integrations

---

## port-registry.sh

Maintains a record of ports assigned to services.

Registry location:

```
/opt/media-stack/ports.json
```

This prevents two plugins from using the same port.

Example registry:

```
{
  "ports": {
    "plex": 32400,
    "radarr": 7878
  }
}
```

---

## port-helper.sh

Provides helper functions used by plugins to safely request ports.

Plugins should **never hardcode port mappings directly**.

Example usage inside plugins:

```
PORT=$(get_port_mapping "radarr" 7878 7878)
```

This registers the port and returns a valid Docker mapping.

---

## plugin-validator.sh

Validates plugins before installation.

Checks include:

* syntax validation
* required metadata fields
* required install function

Required plugin fields:

```
PLUGIN_NAME
PLUGIN_DESCRIPTION
PLUGIN_CATEGORY
PLUGIN_DEPENDS
PLUGIN_PORTS
PLUGIN_HOST_NETWORK
PLUGIN_DASHBOARD
install_service()
```

Running this script ensures plugins follow the Media Stack plugin contract.

---

## media-stack (CLI)

The Media Stack command line interface.

Installed globally as:

```
/usr/local/bin/media-stack
```

Available commands:

```
media-stack install
media-stack update
media-stack status
media-stack restart
media-stack logs
media-stack services
media-stack backup
media-stack doctor
media-stack maintenance
media-stack reset
```

This command is the primary way to manage the stack after installation.

---

## doctor.sh

Performs diagnostic checks on the Media Stack installation.

Checks include:

* installer directory
* stack directory
* Docker installation
* Docker daemon status
* container status
* compose configuration

Example:

```
media-stack doctor
```

---

## backup.sh

Creates compressed backups of the Media Stack configuration.

Backup location:

```
/opt/media-stack-backups/
```

Backup includes:

* docker-compose.yml
* configuration directories
* registry files

Example:

```
media-stack backup
```

---

## updates.sh

Updates both the installer and container images.

Steps performed:

1. Pull latest installer updates from GitHub
2. Validate plugins
3. Pull updated container images
4. Restart containers

Example:

```
media-stack update
```

---

## post-install.sh

Runs automated tasks after installation.

Examples include:

* initializing dashboards
* displaying registered services
* launching monitoring automation

This script runs automatically when installation completes.

---

## health-monitor.sh

Runs a background health monitoring loop.

The script periodically checks all registered services using the service registry:

```
/opt/media-stack/services.json
```

If a service stops responding, a warning is logged.

---

## grafana-dynamic.sh

Automatically configures Grafana after installation.

Tasks performed:

* waits for Grafana to start
* creates Prometheus datasource
* imports dashboards if available

This eliminates the need for manual Grafana configuration.

---

# Summary

The `scripts/` directory contains the operational control layer of the Media Stack.

These scripts provide the automation and management tools that allow the stack to function as a modular plugin-based platform.
