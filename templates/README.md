# Media Stack Templates

The `templates/` directory contains configuration templates used by the Media Stack installer.

Templates provide base configuration files that are used during installation to generate the final runtime configuration of the stack.

These templates allow the installer to dynamically build configuration files without hardcoding them directly into scripts.

This makes the Media Stack easier to maintain and extend.

---

# Template Files

## docker-compose.base.yml

This file is the base Docker Compose template used during installation.

The installer generates the final compose configuration in:

/opt/media-stack/docker-compose.yml

The generation process works as follows:

1. The installer creates a new docker-compose.yml file.
2. The base template defines the structure of the stack.
3. Plugins append their service definitions to the compose file.

Example structure:

version: "3.9"

networks:
  media-network:

services:

After the base file is created, plugins add their container configurations.

Example:

plex:
  image: lscr.io/linuxserver/plex
  network_mode: host

radarr:
  image: lscr.io/linuxserver/radarr
  ports:
    - "7878:7878"

This approach allows the Media Stack to dynamically assemble a Docker Compose stack based on the selected plugins.

---

# Why Templates Are Used

Templates allow the installer to:

- separate configuration from code
- simplify compose file generation
- maintain consistent configuration structure
- allow easy customization in future releases

Using templates also makes it easier to add additional stack configuration in the future without rewriting installer logic.

---

# Future Template Use

Additional templates may be added in future versions of the Media Stack.

Possible examples include:

- monitoring dashboards
- default homepage configuration
- grafana dashboards
- service configuration files

Templates allow these components to be installed automatically during setup.

---

# Summary

The templates directory contains reusable configuration templates that allow the Media Stack installer to dynamically generate the final runtime configuration.