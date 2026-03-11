# Media Stack Download Plugins

The `plugins/download/` directory contains services responsible for downloading media requested by the automation system.

These plugins act as the **download engines** that retrieve media from Usenet or torrent sources.

Within the Media Stack architecture, download services operate between the automation services and the media library.

Typical download pipeline:

```text
Radarr / Sonarr
      ↓
Prowlarr
      ↓
Download Client
      ↓
Unpackerr
      ↓
Media Library
```

---

# Download Plugins

---

## SABnzbd

Software: SABnzbd

SABnzbd is the primary Usenet download client used by the Media Stack.

It downloads media files from Usenet servers based on requests sent by automation services.

### Responsibilities

* download Usenet releases
* verify downloaded files
* extract archives
* manage download queues

### Integration

SABnzbd integrates with several automation services:

* Radarr
* Sonarr
* Bazarr

These services send download requests directly to SABnzbd.

---

### Default Web Interface

```text
http://SERVER-IP:8080
```

The interface allows users to:

* monitor download progress
* manage the download queue
* configure Usenet servers
* manage categories

---

### Storage Location

Downloads are stored in the directory configured during installation.

Example:

```text
/downloads
```

After downloads complete:

1. Files are processed by **Unpackerr**
2. Media files are imported by **Radarr or Sonarr**
3. Media libraries are updated for **Plex**

---

# Download Workflow

Example automated download workflow:

```text
User requests movie
        ↓
Overseerr approves request
        ↓
Radarr searches indexers
        ↓
Prowlarr provides results
        ↓
SABnzbd downloads files
        ↓
Unpackerr extracts archives
        ↓
Radarr imports movie
        ↓
Plex library updates
```

---

# Summary

Download plugins provide the mechanism for retrieving media from external sources.

SABnzbd acts as the central download engine used by the Media Stack automation system.
