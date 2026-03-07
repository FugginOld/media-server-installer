# Media Stack Installer

![License](https://img.shields.io/github/license/FugginOld/media-server-installer)
![Stars](https://img.shields.io/github/stars/FugginOld/media-server-installer)
![Issues](https://img.shields.io/github/issues/FugginOld/media-server-installer)
![Docker](https://img.shields.io/badge/docker-required-blue)
![Platform](https://img.shields.io/badge/platform-linux-green)

Media Stack Installer is a modular Docker-based platform that deploys a complete automated media ecosystem with a single installer.

The project provides a fully automated media server including streaming, downloads, monitoring, and infrastructure services using a plugin-based architecture.

The stack is designed to be:

• Modular  
• Plugin-driven  
• Automatically discoverable  
• Easy to extend  
• Compatible with most Linux environments  

The installer supports both **CLI installation** and **Web installation**.

---

# Features

• One-command media server deployment  
• Plugin-based architecture  
• Automatic plugin discovery  
• Dependency-aware installation  
• Automatic port conflict prevention  
• Service registry for dashboards  
• Hardware acceleration detection  
• Integrated monitoring stack  
• Secure remote access with Tailscale  
• Automatic container updates  
• CLI management tools  

---

# Supported Services

## Media

| Service | Description |
|-------|-------------|
| Plex | Media streaming server |
| Tdarr | Automated media transcoding |

---

## Automation

| Service | Description |
|-------|-------------|
| Radarr | Movie management |
| Sonarr | TV show management |
| Prowlarr | Indexer manager |
| Bazarr | Subtitle automation |
| Overseerr | Media request system |

---

## Download

| Service | Description |
|-------|-------------|
| SABnzbd | Usenet downloader |

---

## Monitoring

| Service | Description |
|-------|-------------|
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards |
| Node Exporter | System metrics |
| Plex Exporter | Plex metrics |
| Tautulli | Plex analytics |
| Glances | Live system monitoring |

---

## System Services

| Service | Description |
|-------|-------------|
| Homepage | Service dashboard |
| Watchtower | Automatic container updates |
| Tailscale | Secure remote access |
| Unpackerr | Archive extraction automation |
| Web Installer | Browser-based installer |

---

# Architecture

The Media Stack uses a **plugin-based architecture**.

```
installer.sh
     │
     ▼
plugin discovery
     │
     ▼
dependency resolution
     │
     ▼
compose generation
     │
     ▼
docker deployment
```

Plugins dynamically generate the Docker Compose configuration.

---

## Media Automation Pipeline

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

---

## Monitoring Stack

```
nodeexporter
plex-exporter
glances
      ↓
   Prometheus
      ↓
    Grafana
```

---

# Installation

## Quick Install

Run the installer directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/FugginOld/media-server-installer/main/install.sh | bash
```

The installer will ask which interface you want:

```
CLI Installer
Web Installer
```

---

# CLI Installation

The CLI installer walks through:

• directory configuration  
• timezone setup  
• plugin selection  
• installation mode  

Installation modes:

```
Quick Install
Custom Install
```

Quick install deploys the recommended media stack.

---

# Web Installer

The Web Installer launches a lightweight container that provides a browser interface for installation.

Default URL:

```
http://SERVER-IP:8088
```

---

# Default Service Ports

| Service | Port |
|------|------|
| Plex | 32400 |
| Radarr | 7878 |
| Sonarr | 8989 |
| Prowlarr | 9696 |
| Bazarr | 6767 |
| Overseerr | 5055 |
| SABnzbd | 8080 |
| Homepage | 3001 |
| Grafana | 3000 |
| Prometheus | 9090 |
| Tautulli | 8181 |
| Glances | 61208 |

Ports are automatically managed using the Media Stack port registry to prevent conflicts.

---

# CLI Management

After installation the `media-stack` command becomes available.

Examples:

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

---

# Directory Structure

```
media-server-installer
├── core
├── scripts
├── plugins
│   ├── media
│   ├── automation
│   ├── download
│   ├── monitoring
│   └── system
├── templates
├── installer.sh
├── install.sh
└── README.md
```

---

# Plugin System

Each plugin defines the following metadata:

```
PLUGIN_NAME
PLUGIN_DESCRIPTION
PLUGIN_CATEGORY
PLUGIN_DEPENDS
PLUGIN_PORTS
PLUGIN_HOST_NETWORK
PLUGIN_DASHBOARD
```

Plugins must implement:

```
install_service()
```

Plugins dynamically append their service configuration to the Docker Compose stack.

New services can be added simply by placing a plugin file inside the `plugins/` directory.

---

# Monitoring

The Media Stack includes a full monitoring platform.

Metrics include:

• CPU usage  
• memory usage  
• disk usage  
• network traffic  
• Plex streaming activity  
• container health  

All metrics are visualized through Grafana dashboards.

---

# Hardware Acceleration

The installer automatically detects available GPU hardware.

Supported acceleration:

• Intel QuickSync  
• AMD VAAPI  
• NVIDIA NVENC  

Services such as Plex and Tdarr automatically enable hardware acceleration when supported hardware is detected.

---

# Compatibility

The Media Stack has been tested on:

• Debian  
• Ubuntu  
• Devuan  
• Proxmox  
• Generic Linux hosts  

Any Linux system capable of running Docker should work.

---

# Contributing

Contributions are welcome.

To add new services, create a plugin that follows the Media Stack plugin contract.

Before submitting changes run:

```
bash scripts/plugin-validator.sh
```

---

# License

This project is licensed under the MIT License.

See the LICENSE file for details.