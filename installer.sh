#!/usr/bin/env bash

set -e

########################################
# Variables
########################################

STACK_DIR="/opt/media-stack"
PLUGIN_DIR="./plugins"
TEMPLATE_FILE="./templates/docker-compose.base.yml"

SELECTED_SERVICES=()
INSTALLED_SERVICES=()

########################################
# Load core modules
########################################

source ./core/platform.sh
source ./core/directories.sh
source ./core/hardware.sh
source ./core/docker.sh

########################################
# Detect system
########################################

echo "Detecting system configuration..."

detect_platform
configure_storage_paths

select_directory_layout
configure_media_directories
create_media_folders

detect_gpu
configure_gpu_devices

########################################
# Prepare docker compose
########################################

echo "Preparing docker stack..."

mkdir -p $STACK_DIR
mkdir -p $STACK_DIR/config

cp $TEMPLATE_FILE $STACK_DIR/docker-compose.yml

########################################
# Discover plugins
########################################

echo "Discovering plugins..."

MENU_OPTIONS=()

for FILE in $(find $PLUGIN_DIR -name "*.sh")
do

unset PLUGIN_NAME
unset PLUGIN_DESCRIPTION
unset PLUGIN_CATEGORY
unset PLUGIN_DEPENDS

source "$FILE"

MENU_OPTIONS+=("$PLUGIN_NAME" "$PLUGIN_CATEGORY - $PLUGIN_DESCRIPTION" OFF)

done

########################################
# Service selection menu
########################################

SELECTED=$(whiptail \
--title "Media Stack Installer" \
--checklist "Select services to install:" \
25 80 18 \
"${MENU_OPTIONS[@]}" \
3>&1 1>&2 2>&3)

########################################
# Convert selection
########################################

for SERVICE in $SELECTED
do
SERVICE=$(echo $SERVICE | tr -d '"')
SELECTED_SERVICES+=("$SERVICE")
done

########################################
# Dependency resolver
########################################

resolve_dependencies() {

CHANGED=true

while [ "$CHANGED" = true ]
do

CHANGED=false

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE=$(find $PLUGIN_DIR -name "$SERVICE.sh")

unset PLUGIN_DEPENDS
source "$PLUGIN_FILE"

for DEP in "${PLUGIN_DEPENDS[@]}"
do

if [[ ! " ${SELECTED_SERVICES[@]} " =~ " ${DEP} " ]]; then

echo "Adding dependency: $DEP"

SELECTED_SERVICES+=("$DEP")
CHANGED=true

fi

done

done

done

}

resolve_dependencies

########################################
# Install plugins
########################################

install_plugin() {

SERVICE=$1

if [[ " ${INSTALLED_SERVICES[@]} " =~ " ${SERVICE} " ]]; then
return
fi

PLUGIN_FILE=$(find $PLUGIN_DIR -name "$SERVICE.sh")

source "$PLUGIN_FILE"

echo "Installing $SERVICE"

install_service

INSTALLED_SERVICES+=("$SERVICE")

}

for SERVICE in "${SELECTED_SERVICES[@]}"
do
install_plugin "$SERVICE"
done

########################################
# Deploy containers
########################################

echo "Starting containers..."

cd $STACK_DIR

docker compose up -d

########################################
# Run post install automation
########################################

if [ -f "./scripts/post-install.sh" ]; then

echo "Running post-install configuration..."

bash ./scripts/post-install.sh

fi

########################################
# Finish
########################################

echo ""
echo "-----------------------------------"
echo " Media Stack Installation Complete "
echo "-----------------------------------"

echo ""

echo "Installed services:"

for SERVICE in "${INSTALLED_SERVICES[@]}"
do
echo " - $SERVICE"
done

echo ""

echo "Docker stack location:"
echo "$STACK_DIR"

echo ""
