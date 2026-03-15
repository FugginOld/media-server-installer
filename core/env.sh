########################################
# Load environment
########################################

# Prevent double-loading
if [ -n "${MEDIA_STACK_ENV_LOADED:-}" ]; then
    return
fi
export MEDIA_STACK_ENV_LOADED=1

########################################
# Load runtime if needed
########################################

if [ -z "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"
source "$INSTALL_DIR/lib/runtime.sh"
fi

########################################
# Stack directories
########################################

STACK_DIR="${STACK_DIR:-/opt/media-stack}"

CONFIG_DIR="${CONFIG_DIR:-$STACK_DIR/config}"
LOG_DIR="${LOG_DIR:-$STACK_DIR/logs}"
BACKUP_DIR="${BACKUP_DIR:-$STACK_DIR/backups}"

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
# Detect container user (PUID / PGID)
########################################

if [ -n "${PUID:-}" ]; then

PGID="${PGID:-$PUID}"

else

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
USER_NAME="$SUDO_USER"

elif [ "$(id -u)" -ne 0 ]; then
USER_NAME="$(whoami)"

else
if getent passwd 1000 >/dev/null; then
USER_NAME="$(getent passwd 1000 | cut -d: -f1)"
else
USER_NAME="root"
fi
fi

PUID="$(id -u "$USER_NAME" 2>/dev/null || echo 1000)"
PGID="$(id -g "$USER_NAME" 2>/dev/null || echo 1000)"

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
echo "Detected HOST_IP=${HOST_IP:-unknown}"
echo ""

########################################
# Export variables
########################################

export STACK_DIR
export CONFIG_DIR
export LOG_DIR
export BACKUP_DIR

export SERVICE_REGISTRY
export PORT_REGISTRY

export MEDIA_PATH
export MOVIES_PATH
export TV_PATH
export DOWNLOADS_PATH

export PUID
export PGID
export TIMEZONE