########################################
# Load environment
########################################

# Prevent double-loading
if [ -n "${MEDIA_STACK_ENV_LOADED:-}" ]; then
return
fi
export MEDIA_STACK_ENV_LOADED=1

########################################
# Stack directory
########################################

STACK_DIR="/opt/media-stack"

########################################
# Core directories
########################################

CONFIG_DIR="$STACK_DIR/config"
LOG_DIR="$STACK_DIR/logs"
BACKUP_DIR="$STACK_DIR/backups"

########################################
# Plugin architecture
########################################

PLUGIN_DIR="$INSTALL_DIR/plugins"

########################################
# Registry files
########################################

SERVICE_REGISTRY="$STACK_DIR/services.json"
PORT_REGISTRY="$STACK_DIR/ports.json"

########################################
# Default media directories
########################################

MEDIA_PATH="${MEDIA_PATH:-/media}"
MOVIES_PATH="${MOVIES_PATH:-/media/movies}"
TV_PATH="${TV_PATH:-/media/tv}"
DOWNLOADS_PATH="${DOWNLOADS_PATH:-/downloads}"

########################################
# Load saved environment variables
########################################

if [ -f "$STACK_DIR/stack.env" ]; then
# shellcheck disable=SC1090
source "$STACK_DIR/stack.env"
fi

########################################
# Ensure base directories exist
########################################

mkdir -p "$STACK_DIR" "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"

########################################
# Ensure registry files exist
########################################

if [ ! -f "$SERVICE_REGISTRY" ]; then
echo '{"services":[]}' > "$SERVICE_REGISTRY"
fi

if [ ! -f "$PORT_REGISTRY" ]; then
echo '{}' > "$PORT_REGISTRY"
fi

########################################
# Detect container user
########################################

if [ -n "${PUID:-}" ]; then
# user explicitly defined
PUID="$PUID"
PGID="${PGID:-$PUID}"

else

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then

USER_NAME="$SUDO_USER"

elif [ "$(id -u)" -ne 0 ]; then

USER_NAME="$(whoami)"

else

# fallback to UID 1000 if root and no sudo user
USER_NAME="$(getent passwd 1000 | cut -d: -f1 || true)"

fi

if [ -n "${USER_NAME:-}" ]; then

PUID="$(id -u "$USER_NAME" 2>/dev/null || echo 1000)"
PGID="$(id -g "$USER_NAME" 2>/dev/null || echo 1000)"

else

PUID=1000
PGID=1000

fi

fi

########################################
# Timezone
########################################

TIMEZONE="${TIMEZONE:-UTC}"

########################################
# Display runtime values
########################################

echo ""
echo "Using PUID=$PUID"
echo "Using PGID=$PGID"
echo ""

########################################
# Export variables
########################################

export INSTALL_DIR
export STACK_DIR
export CONFIG_DIR
export LOG_DIR
export BACKUP_DIR
export PLUGIN_DIR

export SERVICE_REGISTRY
export PORT_REGISTRY

export MEDIA_PATH
export MOVIES_PATH
export TV_PATH
export DOWNLOADS_PATH

export PUID
export PGID
export TIMEZONE
