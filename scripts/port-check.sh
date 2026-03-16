#!/usr/bin/env bash
set -euo pipefail

########################################
# Load runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/plugins.sh"

########################################
# Port conflict detection
########################################

echo ""
echo "================================"
echo "Checking Port Availability"
echo "================================"
echo ""

CONFLICTS=()
CHECKED_PORTS=()

########################################
# Resolve selected services
########################################

if [[ "$#" -gt 0 ]]; then
    SELECTED_SERVICES=("$@")
fi

load_plugins

########################################
# Validate selected services
########################################

if [[ -z "${SELECTED_SERVICES+x}" ]]; then
warn "No services defined for port checking"
exit 0
fi

if [[ "${#SELECTED_SERVICES[@]}" -eq 0 ]]; then
warn "No services selected"
exit 0
fi

########################################
# Check if port is in use
########################################

port_in_use() {

local PORT="$1"

ss -tuln | awk '{print $5}' | grep -q ":$PORT$"

}

########################################
# Scan selected plugins
########################################

for SERVICE in "${SELECTED_SERVICES[@]}"
do

[[ -z "$SERVICE" ]] && continue

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]:-}"

if [[ -z "$PLUGIN_FILE" ]]; then
warn "Missing plugin path for $SERVICE"
continue
fi

# shellcheck disable=SC1090
source "$PLUGIN_FILE"

########################################
# Skip plugins without ports
########################################

if [[ -z "${PLUGIN_PORT:-}" ]]; then
    continue
fi

if port_in_use "$PLUGIN_PORT"; then

    PROCESS=$(ss -tulnp 2>/dev/null | grep ":$PLUGIN_PORT " | awk '{print $NF}' | head -n1)
    CONFLICTS+=("$PLUGIN_PORT ($PROCESS)")

else

    CHECKED_PORTS+=("$PLUGIN_PORT")

fi

done

########################################
# Display results
########################################

echo ""
echo "Ports checked:"

if [[ "${#CHECKED_PORTS[@]}" -eq 0 ]]; then
echo "  none"
else
printf "  %s\n" "${CHECKED_PORTS[@]}"
fi

echo ""

########################################
# Conflict handling
########################################

if [[ "${#CONFLICTS[@]}" -gt 0 ]]; then

MSG=$(printf "%s\n" "${CONFLICTS[@]}")

whiptail \
--title "Port Conflicts Detected" \
--msgbox "The following ports are already in use:

$MSG

The installer will attempt automatic reassignment." \
15 70

else

echo "All required ports available."

fi
