# Media Stack Core Modules

The `core/` directory contains the foundational modules used by the Media Stack installer.

These scripts provide system detection, configuration, environment preparation, and infrastructure setup required before plugins are installed.

All modules in this directory are loaded by:

installer.sh

These scripts ensure the system environment is prepared correctly regardless of Linux distribution or NAS platform.

---

# Core Module Overview

## platform.sh

Detects the operating system and determines the appropriate platform configuration.

This module identifies:

• Linux distribution  
• Platform family  
• Package manager  
• NAS platforms  

Supported Linux families:

Debian-based
- Debian
- Ubuntu
- Devuan
- Linux Mint
- Pop!_OS

RedHat-based
- Fedora
- Rocky Linux
- AlmaLinux
- RHEL

Arch-based
- Arch Linux
- Manjaro

SUSE
- openSUSE
- SLES

Lightweight systems
- Alpine Linux

The module also provides package manager abstraction functions:

pkg_update  
pkg_install  

These allow other scripts to install packages without needing distribution-specific commands.

---

## NAS Platform Detection

The installer automatically detects common NAS environments and adjusts behavior accordingly.

Supported NAS systems:

• Unraid  
• TrueNAS SCALE  
• OpenMediaVault  
• CasaOS  

When a NAS environment is detected, the installer applies appropriate permission adjustments to ensure containers can access storage volumes correctly.

---

## directories.sh

Defines the directory layout used by the Media Stack.

The installer allows users to select between:

Default layout
or
TRaSH Guides directory structure

Typical directories include:

/media  
/movies  
/tv  
/downloads  

These paths are exported as environment variables used by plugins.

Example variables:

MEDIA_PATH  
MOVIES_PATH  
TV_PATH  
DOWNLOADS_PATH  

These variables ensure containers share consistent storage locations.

---

## hardware.sh

Detects hardware acceleration capabilities.

Supported GPU types:

• Intel iGPU (QuickSync)  
• AMD GPU (VAAPI)  
• NVIDIA GPU (NVENC)

If supported hardware is detected, GPU configuration variables are exported so plugins such as Plex and Tdarr can enable hardware acceleration automatically.

---

## docker.sh

Ensures Docker and Docker Compose are installed and operational.

This module:

• installs Docker when missing  
• starts the Docker daemon  
• enables Docker at system boot  
• installs the Docker Compose plugin  
• adds the current user to the docker group  

Docker installation supports multiple Linux distributions through the platform abstraction layer.

---

## permissions.sh

Handles container permissions and storage access.

This module ensures that media directories are accessible by Docker containers.

Responsibilities include:

• detecting PUID and PGID  
• applying ownership to media directories  
• setting directory permissions  
• applying NAS-specific permission adjustments  

These fixes prevent common problems such as containers being unable to read or write media files.

---

## config-wizard.sh

Provides the interactive CLI configuration wizard.

The wizard collects configuration values such as:

• timezone  
• directory structure  
• media locations  
• container user IDs  

Configuration values are stored in:

/opt/media-stack/stack.env

This file is loaded during installation and used by plugins.

---

# Summary

The `core/` modules provide the infrastructure layer for the Media Stack installer.

These scripts handle platform detection, Docker installation, hardware support, storage configuration, and environment preparation.

By abstracting these responsibilities into reusable modules, the installer can support many different Linux distributions and NAS environments while keeping plugin installation simple and consistent.