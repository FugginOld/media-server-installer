# Media Stack Automation Plugins

The `plugins/automation/` directory contains services that automate the process of discovering, requesting, and organizing media.

These plugins work together to create a fully automated media acquisition workflow.

Typical automation pipeline:

```text
Overseerr
     ↓
Radarr / Sonarr
     ↓
Prowlarr
     ↓
Sabnzbd
     ↓
Unpackerr
     ↓
Media Library
```

The automation system ensures that once a user requests media, the entire process from discovery to streaming happens automatically.

---

# Automation Plugins

---

## Radarr

Software: Radarr

Radarr manages movie libraries and automatically downloads new releases.

### Responsibilities

* monitor movie collections
* search for releases
* send downloads to SABnzbd
* organize downloaded movies

### Integrations

Radarr integrates with:

* Prowlarr (indexers)
* SABnzbd (downloads)
* Plex (library)

### Default Interface

```
http://SERVER-IP:7878
```

---

## Sonarr

Software: Sonarr

Sonarr performs the same role as Radarr but for TV series.

### Responsibilities

* monitor TV shows
* download missing episodes
* upgrade to better quality releases
* organize TV libraries

### Integrations

Sonarr integrates with:

* Prowlarr
* SABnzbd
* Plex

### Default Interface

```
http://SERVER-IP:8989
```

---

## Prowlarr

Software: Prowlarr

Prowlarr manages Usenet and torrent indexers.

It connects to multiple indexers and automatically synchronizes them with Radarr and Sonarr.

### Responsibilities

* manage indexer configuration
* distribute indexers to Radarr and Sonarr
* simplify indexer management

### Default Interface

```
http://SERVER-IP:9696
```

---

## Bazarr

Software: Bazarr

Bazarr automatically downloads subtitles for media files managed by Radarr and Sonarr.

### Responsibilities

* scan movie and TV libraries
* search subtitle providers
* download subtitles automatically

### Integrations

Bazarr connects to:

* Radarr
* Sonarr

### Default Interface

```
http://SERVER-IP:6767
```

---

## Overseerr

Software: Overseerr

Overseerr provides a user-friendly interface where users can request movies and TV shows.

Once approved, requests are automatically sent to Radarr or Sonarr.

### Responsibilities

* handle user media requests
* integrate with Plex libraries
* forward requests to automation services

### Default Interface

```
http://SERVER-IP:5055
```

---

# Automation Workflow

The Media Stack automation system provides a fully automated pipeline.

Example workflow:

```text
User requests movie
        ↓
Overseerr sends request
        ↓
Radarr searches indexers
        ↓
Prowlarr provides sources
        ↓
Sabnzbd downloads release
        ↓
Unpackerr extracts files
        ↓
Radarr imports media
        ↓
Plex library updates
```

This system allows users to request media and have it automatically downloaded and available for streaming.

---

# Summary

Automation plugins are responsible for discovering, requesting, and managing media downloads.

They integrate tightly with the downloader, media services, and monitoring components to create a fully automated media server environment.
