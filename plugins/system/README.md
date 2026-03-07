# Media Stack System Plugins

The `plugins/system/` directory contains infrastructure services that support the Media Stack platform.

These services provide features such as:

- service dashboards
- automatic container updates
- secure remote access
- download processing
- web-based installation tools

These plugins are not directly responsible for serving or downloading media, but they provide critical platform functionality.

---

# System Plugins

## Homepage

Homepage provides a centralized dashboard for accessing all Media Stack services.

Homepage automatically displays services that register themselves in the Media Stack service registry.

Registry location:

/opt/media-stack/services.json

Features:

- service links
- grouped dashboards
- container health visibility
- customizable widgets

Default interface:

http://SERVER-IP:3001

---

## Watchtower

Watchtower automatically updates Docker containers.

It periodically checks for updated container images and performs upgrades safely.

Features:

- automatic container updates
- scheduled updates
- old image cleanup

Typical schedule:

Daily automatic container update checks.

This prevents the need to manually run updates for containers.

---

## Tailscale

Tailscale provides secure remote access to the Media Stack.

It creates a private VPN network between your devices using WireGuard.

Features:

- secure remote access
- encrypted networking
- no router port forwarding required

After authentication, services become accessible via the Tailscale network.

Example:

http://100.x.x.x:32400

This allows remote access to Plex and other services without exposing them publicly.

---

## Unpackerr

Unpackerr automatically extracts downloaded releases.

Some Usenet downloads contain compressed archives that must be unpacked before Radarr or Sonarr can import them.

Unpackerr monitors the download directory and extracts files automatically.

Integrations:

- SABnzbd
- Radarr
- Sonarr

This ensures downloads are processed immediately after completion.

---

## Web Installer

The Web Installer plugin provides a browser-based entry point for installing or managing the Media Stack.

This allows users to launch the installer from a web interface instead of the command line.

Default interface:

http://SERVER-IP:8088

The Web Installer can be used for:

- launching installation workflows
- providing documentation links
- redirecting users to dashboards

---

# Summary

System plugins provide infrastructure and management functionality for the Media Stack.

These services improve usability, automation, and remote accessibility for the platform.