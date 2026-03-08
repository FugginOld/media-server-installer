#!/usr/bin/env bash

########################################
# Media Stack Configuration Wizard
#
# Collects runtime configuration for
# the Media Stack installation and
# saves it to stack.env
########################################

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

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
# Load existing configuration if present
########################################

if [ -f "$CONFIG_FILE" ]; then
source "$CONFIG_FILE"
fi

########################################
# Detect timezone
########################################

DEFAULT_TZ=${TIMEZONE:-$(timedatectl show --property=Timezone --value 2>/dev/null)}

if [ -z "$DEFAULT_TZ" ]; then
DEFAULT_TZ="UTC"
fi

read -rp "Timezone [$DEFAULT_TZ]: " INPUT
TIMEZONE=${INPUT:-$DEFAULT_TZ}

########################################
# Detect user ID
########################################

DEFAULT_UID=${PUID:-$(id -u)}

read -rp "PUID [$DEFAULT_UID]: " INPUT
PUID=${INPUT:-$DEFAULT_UID}

########################################
# Detect group ID
########################################

DEFAULT_GID=${PGID:-$(id -g)}

read -rp "PGID [$DEFAULT_GID]: " INPUT
PGID=${INPUT:-$DEFAULT_GID}

########################################
# Docker network configuration
########################################

DEFAULT_NET=${DOCKER_NETWORK:-media-network}

read -rp "Docker network [$DEFAULT_NET]: " INPUT
DOCKER_NETWORK=${INPUT:-$DEFAULT_NET}

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