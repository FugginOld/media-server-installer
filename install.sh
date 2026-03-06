#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/FugginOld/media-server-installer.git"
INSTALL_DIR="/opt/media-server-installer"

echo "-----------------------------------------"
echo " Media Server Installer Bootstrap"
echo "-----------------------------------------"

########################################
# Root check
########################################

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

########################################
# Install base dependencies
########################################

echo "Installing dependencies..."

apt update

apt install -y \
git \
curl \
wget \
whiptail \
docker.io \
docker-compose \
jq \
pciutils

########################################
# Enable docker
########################################

systemctl enable docker
systemctl start docker

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

bash installer.sh
