#!/usr/bin/env bash

########################################
# Config File
########################################

STACK_DIR="/opt/media-stack"
CONFIG_FILE="$STACK_DIR/stack.env"

########################################
# Run Wizard
########################################

run_configuration_wizard() {

echo ""
echo "Media Stack Configuration"
echo ""

mkdir -p "$STACK_DIR"

########################################
# Timezone
########################################

DEFAULT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")

read -rp "Timezone [$DEFAULT_TZ]: " TIMEZONE
TIMEZONE=${TIMEZONE:-$DEFAULT_TZ}

########################################
# User ID
########################################

DEFAULT_UID=$(id -u)

read -rp "PUID [$DEFAULT_UID]: " PUID
PUID=${PUID:-$DEFAULT_UID}

########################################
# Group ID
########################################

DEFAULT_GID=$(id -g)

read -rp "PGID [$DEFAULT_GID]: " PGID
PGID=${PGID:-$DEFAULT_GID}

########################################
# Docker Network
########################################

DEFAULT_NET="media-network"

read -rp "Docker network [$DEFAULT_NET]: " DOCKER_NETWORK
DOCKER_NETWORK=${DOCKER_NETWORK:-$DEFAULT_NET}

########################################
# Save Configuration
########################################

cat <<EOF > "$CONFIG_FILE"
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
DOCKER_NETWORK=$DOCKER_NETWORK
EOF

echo ""
echo "Configuration saved:"
echo "$CONFIG_FILE"
echo ""

}