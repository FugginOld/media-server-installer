# Media Stack System Plugins

The `plugins/system/` directory contains infrastructure services that support the Media Stack platform.

These plugins provide core platform capabilities such as:

- service dashboards
- container update automation
- secure remote access
- download processing
- web-based installer interface

System plugins improve the usability, reliability, and accessibility of the Media Stack but are not directly responsible for media streaming or downloading.

---

# System Plugins

## Homepage

Homepage provides a centralized dashboard for accessing Media Stack services.

Homepage automatically displays services registered in the Media Stack service registry.

Registry location:

/opt/media-stack/services.json

Features include:

- categorized service links
- service icons
- quick access to all installed applications
- customizable widgets

Default interface:

http://SERVER-IP:3001

---

## Watchtower

Watchtower automatically updates Docker containers when new images become available.

Responsibilities:

- check for container updates
- download updated images
- restart containers safely

This keeps the Media Stack up to date without requiring manual container updates.

Typical update cycle:

Daily update checks.

---

## Tailscale

Tailscale provides secure remote access to the Media Stack.

Tailscale creates a private network between devices using WireGuard-based VPN technology.

Features:

- secure remote access
- encrypted networking
- no port forwarding required
- private IP access

Example access through Tailscale network:

http://100.x.x.x:32400

This allows users to securely access Plex and other services from outside their home network.

---

## Unpackerr

Unpackerr automatically extracts downloaded releases.

Some Usenet downloads contain compressed archives that must be extracted before Radarr or Sonarr can import them.

Unpackerr monitors download directories and extracts files automatically.

Integrations:

- SABnzbd
- Radarr
- Sonarr

Workflow:

download complete  
→ archive extracted  
→ Radarr/Sonarr import media  

This eliminates manual extraction steps.

---

## Web Installer

The Web Installer plugin provides a browser-based installation interface.

This allows users to launch the Media Stack installer through a web browser instead of the CLI.

Default interface:

http://SERVER-IP:8088

The web installer provides:

- guided installation
- documentation access
- simplified onboarding for new users

---

# Infrastructure Responsibilities

System plugins handle key infrastructure responsibilities including:

Dashboard Management

- Homepage service dashboard

Container Lifecycle Management

- Watchtower automatic updates

Remote Connectivity

- Tailscale secure networking

Download Processing

- Unpackerr archive extraction

Installer Access

- Web Installer interface

---

# NAS Compatibility

System plugins are compatible with NAS platforms supported by the Media Stack installer.

Supported NAS environments:

- Unraid
- TrueNAS SCALE
- OpenMediaVault
- CasaOS

The installer automatically applies permission fixes to ensure containers can access shared storage directories correctly.

---

# Summary

The `system/` plugins provide infrastructure services that make the Media Stack easier to manage, access, and maintain.

These services enhance usability by providing dashboards, remote connectivity, automated updates, and simplified installation tools.