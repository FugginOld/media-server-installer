#!/usr/bin/env bash
set -euo pipefail

########################################
# Load media-stack runtime
########################################

source "${INSTALL_DIR:-/opt/media-server-installer}/lib/runtime.sh"

########################################
# Plugin Validation
########################################

echo ""
echo "================================"
echo "Plugin Validation"
echo "================================"
echo ""

FAIL=0
COUNT=0

########################################
# Ensure plugin directory exists
########################################

if [ ! -d "${PLUGIN_DIR:-}" ]; then
echo "Plugin directory not found: $PLUGIN_DIR"
exit 1
fi

########################################
# Helper: check required field
########################################

check_field() {

FIELD="$1"
FILE="$2"

if ! grep -qE "^[[:space:]]*${FIELD}=" "$FILE"; then
echo "  Missing $FIELD"
FAIL=1
fi

}

########################################
# Helper: check required function
########################################

check_function() {

FUNC="$1"
FILE="$2"

if ! grep -qE "(^${FUNC}\(\)|^function[[:space:]]+${FUNC})" "$FILE"; then
echo "  Missing function: ${FUNC}()"
FAIL=1
fi

}

########################################
# Scan plugins recursively
########################################

while IFS= read -r FILE
do

PLUGIN_FILE=$(basename "$FILE")

echo "Validating $PLUGIN_FILE"

check_field "PLUGIN_NAME" "$FILE"
check_field "PLUGIN_CATEGORY" "$FILE"

check_function "install_service" "$FILE"

COUNT=$((COUNT+1))

done < <(
find "$PLUGIN_DIR" -type f -name "*.sh" \
! -path "*/_template/*" \
! -path "*/README.md"
)

########################################
# Ensure plugins were found
########################################

if [ "$COUNT" -eq 0 ]; then
echo "No plugins discovered."
exit 1
fi

echo ""
echo "Plugins checked: $COUNT"

########################################
# Fail if errors found
########################################

if [ "$FAIL" -eq 1 ]; then
echo ""
echo "Plugin validation failed."
exit 1
fi

echo "All plugins validated successfully."
echo ""