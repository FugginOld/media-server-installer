#!/usr/bin/env bash

########################################
# Media Stack Plugin Validator
#
# Validates plugin scripts before the
# installer executes them.
########################################

########################################
# Load environment
########################################

source "$INSTALL_DIR/core/env.sh"

echo ""
echo "================================"
echo " Plugin Validation"
echo "================================"
echo ""

FAIL=0
COUNT=0

########################################
# Ensure plugin directory exists
########################################

if [ ! -d "$PLUGIN_DIR" ]; then
echo "Plugin directory not found: $PLUGIN_DIR"
exit 1
fi

########################################
# Validate plugins
########################################

while IFS= read -r FILE
do

COUNT=$((COUNT+1))

PLUGIN=$(basename "$FILE")

echo "Checking plugin: $PLUGIN"

########################################
# Syntax check
########################################

if ! bash -n "$FILE"; then
echo "  Syntax error detected"
FAIL=1
fi

########################################
# Required metadata fields
########################################

check_field() {

FIELD=$1

if ! grep -q "$FIELD=" "$FILE"; then
echo "  Missing $FIELD"
FAIL=1
fi

}

check_field "PLUGIN_NAME"
check_field "PLUGIN_DESCRIPTION"
check_field "PLUGIN_CATEGORY"
check_field "PLUGIN_VERSION"
check_field "PLUGIN_IMAGE"
check_field "PLUGIN_DEPENDS"
check_field "PLUGIN_PORTS"
check_field "PLUGIN_HOST_NETWORK"
check_field "PLUGIN_DASHBOARD"

########################################
# Validate install function
########################################

if ! grep -q "install_service()" "$FILE"; then
echo "  Missing install_service()"
FAIL=1
fi

echo ""

done < <(find "$PLUGIN_DIR" -maxdepth 1 -type f -name "*.sh")

########################################
# Ensure plugins exist
########################################

if [ "$COUNT" -eq 0 ]; then
echo "No plugins found in $PLUGIN_DIR"
exit 1
fi

########################################
# Final result
########################################

if [ "$FAIL" -eq 1 ]; then
echo "Plugin validation failed."
exit 1
else
echo "All $COUNT plugins passed validation."
fi