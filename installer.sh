#!/bin/bash

set -e

STACK_DIR="/opt/media-stack"
PLUGIN_DIR="./plugins"
TEMPLATE_FILE="./templates/docker-compose.base.yml"

source ./core/hardware.sh

detect_gpu
get_gpu_devices

mkdir -p $STACK_DIR
mkdir -p $STACK_DIR/config

cp $TEMPLATE_FILE $STACK_DIR/docker-compose.yml

########################################
# Discover plugins
########################################

MENU_OPTIONS=()

for FILE in $PLUGIN_DIR/*.sh
do

unset PLUGIN_NAME
unset PLUGIN_DESCRIPTION
unset PLUGIN_CATEGORY
unset PLUGIN_DEPENDS

source "$FILE"

MENU_OPTIONS+=("$PLUGIN_NAME" "$PLUGIN_CATEGORY - $PLUGIN_DESCRIPTION" OFF)

done

########################################
# Menu
########################################

SELECTED=$(whiptail \
--title "Media Stack Installer" \
--checklist "Select services to install:" \
25 80 15 \
"${MENU_OPTIONS[@]}" \
3>&1 1>&2 2>&3)

########################################
# Convert selection
########################################

SELECTED_SERVICES=()

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

PLUGIN_FILE="$PLUGIN_DIR/$SERVICE.sh"

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

INSTALLED_SERVICES=()

install_plugin() {

SERVICE=$1

if [[ " ${INSTALLED_SERVICES[@]} " =~ " ${SERVICE} " ]]; then
return
fi

PLUGIN_FILE="$PLUGIN_DIR/$SERVICE.sh"

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
# Deploy stack
########################################

cd $STACK_DIR

docker compose up -d

echo ""
echo "Media Stack Installation Complete"
