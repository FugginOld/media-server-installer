#!/usr/bin/env bash

########################################
# Docker Installation Module
########################################

########################################
# Check if Docker exists
########################################

docker_installed() {

if command -v docker >/dev/null 2>&1; then
    return 0
else
    return 1
fi

}

########################################
# Install Docker
########################################

install_docker() {

echo "Installing Docker..."

case "$PLATFORM_FAMILY" in

########################################
# Debian / Ubuntu / Devuan
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

pkg_install \
dnf-plugins-core

dnf config-manager \
--add-repo https://download.docker.com/linux/fedora/docker-ce.repo

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
# Add user to docker group
########################################

configure_docker_permissions() {

if [ -n "$SUDO_USER" ]; then

usermod -aG docker "$SUDO_USER"

echo ""
echo "User $SUDO_USER added to docker group."
echo "You may need to log out and back in."

fi

}

########################################
# Ensure Docker is installed
########################################

ensure_docker() {

if docker_installed; then

echo "Docker already installed."

else

install_docker

fi

enable_docker_service

configure_docker_permissions

}

########################################
# Export function
########################################

export -f ensure_docker