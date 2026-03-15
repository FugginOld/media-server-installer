#!/usr/bin/env bash

########################################
# Load runtime if not already loaded
########################################

if [ -z "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"
source "$INSTALL_DIR/lib/runtime.sh"
fi

########################################
# Docker Management
########################################

########################################
# Check if Docker exists
########################################

docker_installed() {

command -v docker >/dev/null 2>&1

}

########################################
# Install Docker
########################################

install_docker() {

echo "Installing Docker..."

case "$PLATFORM_FAMILY" in

########################################
# Debian / Ubuntu
########################################

debian)

pkg_update

pkg_install \
ca-certificates \
curl \
gnupg \
lsb-release

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/$PLATFORM_ID/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$PLATFORM_ID \
$(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

pkg_update

pkg_install \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

;;

########################################
# RedHat / Fedora
########################################

redhat)

pkg_update

pkg_install dnf-plugins-core

dnf config-manager \
--add-repo https://download.docker.com/linux/$PLATFORM_ID/docker-ce.repo

pkg_install \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

;;

########################################
# Arch Linux
########################################

arch)

pkg_update

pkg_install \
docker \
docker-compose

;;

########################################
# openSUSE
########################################

suse)

pkg_update

pkg_install \
docker \
docker-compose

;;

########################################
# Alpine
########################################

alpine)

pkg_update

pkg_install \
docker \
docker-cli-compose

;;

########################################
# Unsupported platform
########################################

*)

echo "Unsupported Linux platform for automatic Docker installation."
echo "Please install Docker manually."
exit 1

;;

esac

}

########################################
# Enable Docker Service
########################################

enable_docker_service() {

echo "Starting Docker service..."

if command -v systemctl >/dev/null 2>&1; then

systemctl enable docker
systemctl start docker

else

service docker start

fi

}

########################################
# Configure docker group permissions
########################################

configure_docker_permissions() {

if ! getent group docker >/dev/null; then
groupadd docker
fi

if [ -n "${SUDO_USER:-}" ]; then

usermod -aG docker "$SUDO_USER"

echo ""
echo "User $SUDO_USER added to docker group."
echo "You may need to log out and back in."

fi

}

########################################
# Verify Docker installation
########################################

verify_docker() {

echo "Verifying Docker installation..."

if docker info >/dev/null 2>&1; then
echo "Docker installation verified."
else
echo "Docker failed to start correctly."
exit 1
fi

}

########################################
# Ensure Docker installed
########################################

ensure_docker() {

if docker_installed; then
echo "Docker already installed."
else
install_docker
fi

enable_docker_service
configure_docker_permissions
verify_docker

}

########################################
# Export functions
########################################

export -f docker_installed
export -f install_docker
export -f enable_docker_service
export -f configure_docker_permissions
export -f verify_docker
export -f ensure_docker