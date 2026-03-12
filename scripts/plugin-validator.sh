#!/usr/bin/env bash
set -euo pipefail

########################################
#Load media-stack runtime environment
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

########################################
#Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

echo ""
echo "================================"
echo "Plugin Validation"
echo "================================"
echo ""

FAIL=0
COUNT=0

########################################
#Ensure plugin directory exists
########################################

if [ ! -d "$PLUGIN_DIR" ]; then
echo "Plugin directory not found: $PLUGIN_DIR"
exit 1
fi

########################################
#Helper: check required field
########################################

check_field() {

local FIELD="$1"
local FILE="$2"

if ! grep -q "^$FIELD=" "$FILE"; then
echo "  Missing $FIELD"
FAIL=1
fi

}

########################################
#Validate plugins
########################################

while IFS= read -r FILE
do

COUNT=$((COUNT+1))

PLUGIN=$(basename "$FILE" .sh)

echo "Checking plugin: $PLUGIN"

########################################
#Syntax check
########################################

if ! bash -n "$FILE"; then
echo "  Syntax error detected"
FAIL=1
fi

########################################
#Required metadata fields
########################################

check_field "PLUGIN_NAME" "$FILE"
check_field "PLUGIN_DESCRIPTION" "$FILE"
check_field "PLUGIN_CATEGORY" "$FILE"
check_field "PLUGIN_DEPENDS" "$FILE"
check_field "PLUGIN_PORTS" "$FILE"
check_field "PLUGIN_HOST_NETWORK" "$FILE"
check_field "PLUGIN_DASHBOARD" "$FILE"

########################################
#Validate install function
########################################

if ! grep -q "install_service()" "$FILE"; then
echo "  Missing install_service()"
FAIL=1
fi

echo ""

done < <(
find "$PLUGIN_DIR" -type f -name "*.sh" \
! -path "*/_template/*"
)

########################################
#Ensure plugins exist
########################################

if [ "$COUNT" -eq 0 ]; then
echo "No plugins found in $PLUGIN_DIR"
exit 1
fi

########################################
#Final result
########################################

if [ "$FAIL" -eq 1 ]; then
echo "Plugin validation failed."
exit 1
else
echo "All $COUNT plugins passed validation."
fi