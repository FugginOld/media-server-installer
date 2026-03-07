# Media Stack Media Plugins

The `plugins/media/` directory contains the core services responsible for serving and processing media.

These plugins manage:

* media streaming
* media transcoding
* library optimization

They operate on the media directories configured during installation.

Example directories:

```text
/media
/movies
/tv
```

These paths are exported by:

```
core/directories.sh
```

and shared across multiple containers.

---

# Media Plugins

The following services are available in this category.

---

## Plex

Software: Plex Media Server

Plex is the primary media streaming platform used by the Media Stack.

It allows users to stream their media libraries to:

* Smart TVs
* Mobile devices
* Web browsers
* Streaming devices

### Features

* hardware transcoding
* remote streaming
* user accounts
* media library management

### Hardware Acceleration

The Media Stack automatically detects available GPUs using:

```
core/hardware.sh
```

Supported GPU acceleration:

* Intel QuickSync
* AMD VAAPI
* NVIDIA NVENC

If a compatible GPU is detected, Plex containers are configured to enable hardware transcoding.

### Default Web Interface

```
http://SERVER-IP:32400/web
```

---

## Tdarr

Software: Tdarr

Tdarr is used to automatically optimize media files.

It scans media libraries and converts files into preferred formats.

Typical use cases include:

* converting video codecs
* reducing file sizes
* standardizing audio formats
* removing unwanted subtitle tracks

### Integration

Tdarr works directly with the same media directories used by Plex.

Example paths:

```
/media
/movies
/tv
```

### Hardware Acceleration

Like Plex, Tdarr can utilize GPU hardware acceleration when available.

This dramatically reduces the time required for transcoding operations.

### Default Web Interface

```
http://SERVER-IP:8265
```

---

# Media Workflow

Media plugins work together with the automation plugins to build the full media pipeline.

Typical workflow:

```text
Overseerr
     ↓
Radarr / Sonarr
     ↓
Sabnzbd
     ↓
Unpackerr
     ↓
Media directories
     ↓
Plex
     ↓
Tdarr optimization
```

This pipeline allows the Media Stack to automatically:

* request media
* download content
* process files
* serve media to users

---

# Summary

The `media/` plugins provide the core functionality for streaming and managing media libraries within the Media Stack.

These services form the center of the entire platform and integrate closely with the automation and monitoring components.
