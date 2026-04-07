# Media Stack Operational Scripts

The `scripts/` directory contains the operational tools used by the Media Stack installer and runtime environment.

These scripts provide management functionality such as:

- Docker container lifecycle management
- service registry management
- port conflict prevention
- plugin validation
- backups and updates
- monitoring automation
- system diagnostics
- CLI management tools

Some scripts run automatically during installation, while others are used after installation through the Media Stack CLI.

Most scripts interact with configuration stored in:

/opt/media-stack

---

# Script Overview

## Compose lifecycle (lib/compose.sh)

Docker Compose lifecycle functions for the Media Stack live in `lib/compose.sh`.
They are sourced automatically by `bin/media-stack` and `scripts/updates.sh`.

Available functions:

compose_up  
compose_down  
compose_restart  
compose_pull  
compose_logs [service]  
compose_status  
compose_validate  

These functions are also available as CLI commands:

media-stack restart  
media-stack status  
media-stack logs [service]  
media-stack verify  

---

## Service registry (lib/services.sh)

Maintains the Media Stack service registry.

Registry location:

/opt/media-stack/services.json

Plugins register themselves using the function:

register_service

The registry stores:

- service name
- service URL
- service category
- service icon

This registry powers:

- the Homepage dashboard
- the `media-stack services` command
- monitoring integrations

---

## Port registry (lib/ports.sh)

Tracks ports assigned to Media Stack services.

Registry location:

/opt/media-stack/ports.json

This system prevents two containers from using the same port.

Example registry entry:

{
  "plex": 32400,
  "radarr": 7878
}

Ports are requested by plugins using:

PORT=$(get_port_mapping "radarr" 7878)

This function:

- checks the port registry
- assigns ports if available
- prevents collisions

Plugins should never hardcode ports directly.

---

## plugin-validator.sh

Validates plugin scripts before installation.

Checks include:

- shell syntax validation
- required metadata fields
- install function presence

Required plugin fields:

PLUGIN_NAME  
PLUGIN_DESCRIPTION  
PLUGIN_CATEGORY  
PLUGIN_DEPENDS  
PLUGIN_PORTS  
PLUGIN_HOST_NETWORK  
PLUGIN_DASHBOARD  
install_service()

Running this script ensures plugin compatibility with the Media Stack installer.

---

## media-stack (CLI)

The Media Stack command line interface.

Installed globally as:

/usr/local/bin/media-stack

Available commands:

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

This CLI provides the primary interface for managing the stack after installation.

---

## doctor.sh

Performs diagnostic checks on the Media Stack environment.

Checks include:

- installer directory
- stack directory
- Docker installation
- Docker daemon status
- compose configuration

Example usage:

media-stack doctor

This helps troubleshoot installation or container issues.

---

## backup.sh

Creates backups of Media Stack configuration.

Backup location:

/opt/media-stack-backups

Backup contents include:

- docker-compose.yml
- service registry
- port registry
- container configuration directories

Example usage:

media-stack backup

---

## updates.sh

Updates both the installer and container images.

Steps performed:

1. Pull latest installer updates from GitHub
2. Validate plugins
3. Pull updated container images
4. Restart containers

Example usage:

media-stack update

---

## post-install.sh

Runs automation tasks after installation completes.

Examples include:

- initializing dashboards
- verifying services
- preparing monitoring configuration

This script runs automatically at the end of installation.

---

## health-monitor.sh

Monitors the health of running services.

This script periodically checks services registered in:

/opt/media-stack/services.json

If a service fails to respond, a warning is logged.

---

## grafana-dynamic.sh

Automates Grafana configuration.

Responsibilities:

- wait for Grafana container startup
- create Prometheus datasource
- configure dashboards

This removes the need for manual Grafana setup.

---

# Summary

The `scripts/` directory provides the operational automation layer for the Media Stack.

These scripts manage container orchestration, service discovery, monitoring setup, updates, backups, and diagnostics.

Together they allow the Media Stack to function as a fully automated and maintainable platform.