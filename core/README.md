# Media Stack Core Modules

The `core/` directory contains the foundational modules used by the Media Stack installer.
These scripts handle platform detection, hardware detection, directory configuration, Docker installation, and the interactive configuration wizard.

These modules are loaded by:

```
installer.sh
```

They provide the core environment required for plugin installation.

---

# Core Module Overview

## platform.sh

Detects the operating system and environment where the Media Stack is being installed.

Examples of detected environments include:

* Debian
* Ubuntu
* Devuan
* Proxmox
* Generic Linux

This information allows the installer to adjust commands and package installation methods if needed.

---

## directories.sh

Defines the directory structure used by the Media Stack.

The installer can configure directories using either:

**Default layout**

```
/data/media
/data/media/movies
/data/media/tv
/data/downloads
```

or the **TRaSH Guides layout**.

The script exports variables used by plugins:

```
MEDIA_PATH
MOVIES_PATH
TV_PATH
DOWNLOADS_PATH
```

These variables ensure all containers share consistent storage paths.

---

## hardware.sh

Detects available GPU hardware and configures Docker container support for hardware acceleration.

Supported GPU types:

* Intel iGPU
* AMD GPU
* NVIDIA GPU

If a compatible GPU is detected, the script exports Docker configuration blocks used by plugins to enable hardware transcoding.

Used primarily by:

```
plex
tdarr
```

---

## docker.sh

Ensures Docker and Docker Compose are installed and available.

Responsibilities include:

* verifying Docker installation
* installing Docker if missing
* starting the Docker daemon
* enabling Docker to start on system boot

This script guarantees that the system is ready to run containers before the installer proceeds.

---

## config-wizard.sh

Provides the interactive configuration wizard used during CLI installation.

The wizard gathers system configuration such as:

* timezone
* user IDs (PUID/PGID)
* directory structure
* media storage locations

The results are saved to:

```
/opt/media-stack/stack.env
```

This file is then loaded by all plugins during installation.

---

# Summary

The `core/` directory provides the infrastructure that powers the Media Stack installer.

These scripts are responsible for preparing the system so that plugins can be installed reliably and consistently across different Linux environments.
