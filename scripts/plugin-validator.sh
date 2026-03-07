#!/usr/bin/env bash

PLUGIN_DIR="./plugins"

########################################
# NEW: Verify plugin directory exists
########################################

if [ ! -d "$PLUGIN_DIR" ]; then
echo "Plugin directory not found:"
echo "$PLUGIN_DIR"
exit 1
fi

echo ""
echo "Plugin Validation"
echo ""

FAIL=0

########################################
# NEW: Use safe file iteration
########################################

while IFS= read -r FILE
do

echo "Checking $FILE"

bash -n "$FILE"

if [ $? -ne 0 ]; then
echo "Syntax error"
FAIL=1
fi

########################################
# Existing validation checks
########################################

grep -q "PLUGIN_NAME" "$FILE" || { echo "Missing PLUGIN_NAME"; FAIL=1; }
grep -q "install_service()" "$FILE" || { echo "Missing install_service"; FAIL=1; }

########################################
# Dashboard validation
########################################

if grep -q "PLUGIN_DASHBOARD=true" "$FILE"; then
grep -q "register_service" "$FILE" || { echo "Missing registry call"; FAIL=1; }
fi
echo ""

done < <(find "$PLUGIN_DIR" -name "*.sh")

########################################
# NEW: Final validation result
########################################

if [ $FAIL -eq 1 ]; then
echo "Plugin validation failed."
exit 1
else
echo "All plugins passed validation."
fi
