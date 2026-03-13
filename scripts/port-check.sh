#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/core/runtime.sh"

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

check_port() {

PORT="$1"

if ss -tuln | grep -q ":$PORT "; then

PROCESS=$(ss -tulnp 2>/dev/null | grep ":$PORT " | awk '{print $NF}' | head -n1)

CONFLICTS+=("$PORT ($PROCESS)")
return 1

else

CHECKED_PORTS+=("$PORT")

fi

}

########################################
# Scan selected plugins
########################################

for SERVICE in "${SELECTED_SERVICES[@]}"
do

PLUGIN_FILE="${PLUGIN_PATHS[$SERVICE]}"

source "$PLUGIN_FILE"

if [ -n "${PLUGIN_PORTS:-}" ]; then

for PORT in "${PLUGIN_PORTS[@]}"
do
check_port "$PORT"
done

fi

done

########################################
# Display results
########################################

echo ""
echo "Ports checked:"
printf "  %s\n" "${CHECKED_PORTS[@]}"

echo ""

########################################
# Conflict handling
########################################

if [ "${#CONFLICTS[@]}" -gt 0 ]; then

MSG=$(printf "%s\n" "${CONFLICTS[@]}")

whiptail \
--title "Port Conflicts Detected" \
--msgbox "The following ports are already in use:

$MSG

Please free these ports or change configuration." \
15 70

exit 1

else

echo "All required ports available."

fi
