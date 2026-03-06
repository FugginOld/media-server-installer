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
# Prepare stack directory
########################################

prepare_stack() {

mkdir -p $STACK_DIR
mkdir -p $STACK_DIR/config

cp $TEMPLATE_FILE $STACK_DIR/docker-compose.yml

}

########################################
# Discover plugins
########################################

discover_plugins() {

MENU_OPTIONS=()

while IFS= read -r FILE
do

unset PLUGIN_NAME
unset PLUGIN_DESCRIPTION
unset PLUGIN_CATEGORY

source "$FILE"

MENU_OPTIONS+=("$PLUGIN_NAME" "$PLUGIN_CATEGORY - $PLUGIN_DESCRIPTION" OFF)

done < <(find $PLUGIN_DIR -name "*.sh")

}

########################################
# Show selection menu
########################################

select_services() {

CHOICES=$(whiptail \
--title "Media Stack Installer" \
--checklist "Select services to install" \
25 80 18 \
"${MENU_OPTIONS[@]}" \
3>&1 1>&2 2>&3)

for SERVICE in $CHOICES
do
SERVICE=$(echo $SERVICE | tr -d '"')
SELECTED_SERVICES+=("$SERVICE")
done

}

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

########################################
# Install plugin
########################################

install_plugin() {

SERVICE=$1

if [[ " ${INSTALLED_SERVICES[@]} " =~ " ${SERVICE} " ]]; then
return
fi

PLUGIN_FILE=$(find $PLUGIN_DIR -name "$SERVICE.sh")

source "$PLUGIN_FILE"

echo "Installing $SERVICE..."

install_service

INSTALLED_SERVICES+=("$SERVICE")

}

########################################
# Install selected services
########################################

install_services() {

for SERVICE in "${SELECTED_SERVICES[@]}"
do
install_plugin "$SERVICE"
done

}

########################################
# Start docker stack
########################################

deploy_stack() {

echo "Starting containers..."

cd $STACK_DIR

docker compose up -d

}

########################################
# Run automation
########################################

post_install() {

if [ -f "./scripts/post-install.sh" ]; then

echo "Running post-install configuration..."

bash ./scripts/post-install.sh

fi

}

########################################
# Display results
########################################

summary() {

echo ""
echo "----------------------------------"
echo " Media Stack Installation Complete"
echo "----------------------------------"
echo ""

echo "Installed services:"

for SERVICE in "${INSTALLED_SERVICES[@]}"
do
echo " - $SERVICE"
done

echo ""

echo "Stack location:"
echo "$STACK_DIR"

echo ""

}

########################################
# Main
########################################

echo ""
echo "================================="
echo " Media Stack Installer"
echo "================================="
echo ""

########################################
# Detect system
########################################

detect_platform
configure_storage_paths

select_directory_layout
configure_media_directories
create_media_folders

detect_gpu
configure_gpu_devices

########################################
# Docker setup
########################################

check_docker
create_docker_network

########################################
# Stack preparation
########################################

prepare_stack

########################################
# Plugin discovery
########################################

discover_plugins

########################################
# User service selection
########################################

select_services

########################################
# Dependency resolution
########################################

resolve_dependencies

########################################
# Install services
########################################

install_services

########################################
# Deploy stack
########################################

deploy_stack

########################################
# Automation
########################################

post_install

########################################
# Summary
########################################

summary