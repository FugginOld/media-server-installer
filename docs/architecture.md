# Media Stack Architecture

This document describes the architecture of the Media Stack platform and how the different components interact.

The Media Stack uses a modular plugin-based architecture that dynamically generates a Docker Compose stack during installation.

---

# High-Level Architecture

```
Installer
   │
   ▼
Platform Detection
   │
   ▼
Environment Preparation
   │
   ▼
Plugin Discovery
   │
   ▼
Dependency Resolution
   │
   ▼
Docker Compose Generation
   │
   ▼
Container Deployment
```

The installer dynamically assembles the final system based on the selected plugins.

---

# Core System Components

The Media Stack is built around several infrastructure layers.

## Core Modules

Located in:

```
core/
```

Core modules handle system preparation and environment detection.

Responsibilities include:

- platform detection
- NAS detection
- hardware detection
- Docker installation
- directory configuration
- container permissions

Core modules loaded by the installer:

```
platform.sh
directories.sh
hardware.sh
docker.sh
permissions.sh
config-wizard.sh
```

---

## Installer

The main installer script is:

```
installer.sh
```

Responsibilities:

- run preflight checks
- detect system platform
- install Docker if required
- run configuration wizard
- discover plugins
- resolve plugin dependencies
- generate docker-compose stack
- deploy containers

The installer supports two modes:

```
CLI Installer
Web Installer
```

---

# Plugin System

All services are implemented as plugins.

Plugins are located in:

```
plugins/
```

Categories include:

```
plugins/
├── media
├── automation
├── download
├── monitoring
└── system
```

Each plugin defines metadata and generates container configuration.

---

# Media Automation Pipeline

The Media Stack provides a fully automated media acquisition pipeline.

```
Overseerr
     ↓
Radarr / Sonarr
     ↓
Prowlarr
     ↓
SABnzbd
     ↓
Unpackerr
     ↓
Media Library
     ↓
Plex
```

User requests media → automation services download it → media appears automatically in Plex.

---

# Monitoring Architecture

The stack includes a full monitoring platform.

```
nodeexporter
plex-exporter
glances
      ↓
   Prometheus
      ↓
    Grafana
```

Metrics collected include:

- CPU usage
- memory usage
- disk utilization
- network traffic
- Plex streaming activity
- container health

---

# Service Registry

The Media Stack uses a service registry.

File location:

```
/opt/media-stack/services.json
```

The registry stores:

- service name
- service URL
- service category
- service icon

This registry powers:

- Homepage dashboard
- CLI service listing
- monitoring integrations

---

# Port Registry

To prevent container port conflicts, the Media Stack uses a port registry.

File location:

```
/opt/media-stack/ports.json
```

Plugins request ports through the port helper system instead of hardcoding them.

---

# Storage Layout

Media and downloads are stored in shared directories.

Example layout:

```
/media
/movies
/tv
/downloads
```

Alternatively users may select the **TRaSH Guides directory structure** during installation.

---

# GPU Acceleration

Hardware acceleration is automatically detected.

Supported GPU technologies:

- Intel QuickSync
- AMD VAAPI
- NVIDIA NVENC

Services such as Plex and Tdarr enable GPU support automatically when hardware is detected.

---

# NAS Compatibility

The Media Stack installer supports several NAS platforms.

Supported systems:

- Unraid
- TrueNAS SCALE
- OpenMediaVault
- CasaOS

The installer automatically applies permission fixes for shared storage environments.

---

# Summary

The Media Stack architecture is designed to be modular, extensible, and portable across many Linux environments.

Key architectural goals:

- plugin-based design
- dynamic service deployment
- automatic dependency management
- cross-platform compatibility
- easy extensibility