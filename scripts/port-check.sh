#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

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
# Check if port is in use
########################################

check_port() {

PORT="$1"

# Skip if already checked
if [[ " ${CHECKED_PORTS[*]} " =~ " ${PORT} " ]]; then
return
fi

if ss -tuln | grep -q ":$PORT "; then

PROCESS=$(ss -tulnp 2>/dev/null | grep ":$PORT " | awk '{print $NF}' | head -n1)

CONFLICTS+=("$PORT ($PROCESS)")
else
CHECKED_PORTS+=("$PORT")
fi

}

########################################
# Scan selected plugins
########################################

if [ -n "${SELECTED_SERVICES:-}" ]; then

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"

# Load plugin metadata
source "$PLUGIN_FILE"

if [ -n "${PLUGIN_PORTS:-}" ]; then

for PORT in "${PLUGIN_PORTS[@]}"
do
check_port "$PORT"
done

fi

done

fi

########################################
# Display results
########################################

echo ""
echo "Ports checked:"

if [ "${#CHECKED_PORTS[@]}" -gt 0 ]; then
printf "  %s\n" "${CHECKED_PORTS[@]}"
else
echo "  none"
fi

echo ""

########################################
# Conflict handling
########################################

if [ "${#CONFLICTS[@]}" -gt 0 ]; then

MSG=$(printf "%s\n" "${CONFLICTS[@]}")

if command -v whiptail >/dev/null 2>&1; then

whiptail \
--title "Port Conflicts Detected" \
--msgbox "The following ports are already in use:

$MSG

Please free these ports or change configuration." \
15 70

else

echo "Port conflicts detected:"
echo "$MSG"

fi

exit 1

else

echo "All required ports available."

fi