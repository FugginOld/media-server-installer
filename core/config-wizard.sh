#!/usr/bin/env bash

########################################
# Configuration Wizard
#
# Collects runtime configuration for
# the Media Stack installation.
########################################

STACK_DIR="/opt/media-stack"
CONFIG_FILE="$STACK_DIR/stack.env"

########################################
# Run configuration wizard
########################################

run_configuration_wizard() {

echo ""
echo "================================"
echo " Media Stack Configuration"
echo "================================"
echo ""

mkdir -p "$STACK_DIR"

########################################
# Detect system timezone
########################################

DEFAULT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null)

if [ -z "$DEFAULT_TZ" ]; then
DEFAULT_TZ="UTC"
fi

read -rp "Timezone [$DEFAULT_TZ]: " TIMEZONE
TIMEZONE=${TIMEZONE:-$DEFAULT_TZ}

########################################
# Detect current user ID
########################################

DEFAULT_UID=$(id -u)

read -rp "PUID [$DEFAULT_UID]: " PUID
PUID=${PUID:-$DEFAULT_UID}

########################################
# Detect group ID
########################################

DEFAULT_GID=$(id -g)

read -rp "PGID [$DEFAULT_GID]: " PGID
PGID=${PGID:-$DEFAULT_GID}

########################################
# Docker network configuration
########################################

DEFAULT_NET="media-network"

read -rp "Docker network [$DEFAULT_NET]: " DOCKER_NETWORK
DOCKER_NETWORK=${DOCKER_NETWORK:-$DEFAULT_NET}

########################################
# Save configuration
########################################

cat <<EOF > "$CONFIG_FILE"
TIMEZONE=$TIMEZONE
PUID=$PUID
PGID=$PGID
DOCKER_NETWORK=$DOCKER_NETWORK
EOF

echo ""
echo "Configuration saved to:"
echo "$CONFIG_FILE"
echo ""

}