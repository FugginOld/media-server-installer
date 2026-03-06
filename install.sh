#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/FugginOld/media-server-installer.git"
INSTALL_DIR="/opt/media-server-installer"

echo ""
echo "================================="
echo " Media Stack Bootstrap Installer"
echo "================================="
echo ""

########################################
# Root check
########################################

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    echo "Example:"
    echo "su -"
    exit 1
fi

########################################
# Install base dependencies
########################################

echo "Installing system dependencies..."

apt update

apt install -y \
curl \
git \
wget \
jq \
whiptail \
pciutils \
ca-certificates \
gnupg \
lsb-release

########################################
# Install Docker (official repo)
########################################

if ! command -v docker >/dev/null 2>&1; then

echo "Installing Docker..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update

apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

systemctl enable docker
systemctl start docker

fi

########################################
# Clone or update repository
########################################

if [ -d "$INSTALL_DIR/.git" ]; then

echo "Updating existing installer..."

cd $INSTALL_DIR
git pull

else

echo "Downloading Media Stack Installer..."

git clone $REPO_URL $INSTALL_DIR

fi

########################################
# Launch installer
########################################

cd $INSTALL_DIR

chmod +x installer.sh

echo ""
echo "Launching installer..."
echo ""

bash installer.sh