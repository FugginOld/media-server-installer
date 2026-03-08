![Version](https://img.shields.io/badge/version-0.1.0--alpha-orange)
![Status](https://img.shields.io/badge/status-alpha-red)

# Media Stack Installer

Media Stack Installer is a modular Docker-based platform that deploys a complete automated media server ecosystem using a plugin-based architecture.

The project installs and configures media services, automation tools, monitoring systems, and infrastructure components with a single installer.

The platform supports both CLI and Web installation methods.

---

# Key Features

• Plugin-based architecture  
• Automatic plugin discovery  
• Dependency-aware plugin installation  
• Automatic Docker installation  
• Cross-platform Linux compatibility  
• NAS platform detection  
• Container permission management  
• Hardware acceleration detection  
• Monitoring stack with Prometheus and Grafana  
• Secure remote access with Tailscale  
• Automatic container updates with Watchtower  
• CLI management tools  

---

# Supported Linux Platforms

The installer supports most major Linux distributions.

## Debian-based

• Debian  
• Ubuntu  
• Devuan  
• Linux Mint  
• Pop!_OS  

## RedHat-based

• Fedora  
• Rocky Linux  
• AlmaLinux  
• RHEL  

## Arch-based

• Arch Linux  
• Manjaro  

## SUSE

• openSUSE  
• SUSE Linux Enterprise  

## Lightweight Systems

• Alpine Linux  

---

# Supported NAS Platforms

The installer automatically detects NAS operating systems and applies container permission fixes when needed.

Supported NAS environments:

• Unraid  
• TrueNAS SCALE  
• OpenMediaVault  
• CasaOS  

---

# Supported Services

## Media

| Service | Purpose |
|-------|-------|
| Plex | Media streaming server |
| Tdarr | Automated media transcoding |

---

## Automation

| Service | Purpose |
|-------|-------|
| Radarr | Movie automation |
| Sonarr | TV automation |
| Prowlarr | Indexer manager |
| Bazarr | Subtitle automation |
| Overseerr | Media request system |

---

## Download

| Service | Purpose |
|-------|-------|
| SABnzbd | Usenet downloader |

---

## Monitoring

| Service | Purpose |
|-------|-------|
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards |
| Node Exporter | System metrics |
| Plex Exporter | Plex metrics |
| Tautulli | Plex analytics |
| Glances | Real-time system monitoring |

---

## Infrastructure

| Service | Purpose |
|-------|-------|
| Homepage | Service dashboard |
| Watchtower | Automatic container updates |
| Tailscale | Secure remote access |
| Unpackerr | Archive extraction |
| Web Installer | Browser installer |

---

# Installation

## Quick Install

Run the installer directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/FugginOld/media-server-installer/main/install.sh | bash
```

The installer will prompt for:

```
CLI Installer
Web Installer
```

---

# CLI Installer

The CLI installer guides users through:

• directory configuration  
• timezone configuration  
• plugin selection  
• installation mode  

Installation modes:

```
Quick Install
Custom Install
```

---

# Web Installer

The Web Installer launches a containerized installer interface.

Default URL:

```
http://SERVER-IP:8088
```

---

# Monitoring Architecture

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

# Media Automation Pipeline

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

# CLI Management

After installation the `media-stack` command becomes available.

Example commands:

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

Plugins define the following metadata:

```
PLUGIN_NAME
PLUGIN_DESCRIPTION
PLUGIN_CATEGORY
PLUGIN_DEPENDS
PLUGIN_PORTS
PLUGIN_HOST_NETWORK
PLUGIN_DASHBOARD
```

Plugins implement the required function:

```
install_service()
```

Plugins dynamically append service definitions to the Docker Compose configuration.

---

# Hardware Acceleration

The installer automatically detects GPU hardware.

Supported acceleration:

• Intel QuickSync  
• AMD VAAPI  
• NVIDIA NVENC  

Services such as Plex and Tdarr enable GPU acceleration automatically when supported hardware is detected.

---

# Contributing

Contributions are welcome.

Before submitting changes run:

```
bash scripts/plugin-validator.sh
```

---

# License

MIT License
