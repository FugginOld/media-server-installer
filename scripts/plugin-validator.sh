#!/usr/bin/env bash

########################################
# Plugin Validator
#
# Validates plugin scripts before the
# installer attempts to execute them.
########################################

PLUGIN_DIR="./plugins"

echo ""
echo "================================"
echo " Plugin Validation"
echo "================================"
echo ""

FAIL=0

########################################
# Validate each plugin script
########################################

for FILE in $(find "$PLUGIN_DIR" -name "*.sh")
do

echo "Checking plugin: $FILE"

########################################
# Syntax check
########################################

bash -n "$FILE"

if [ $? -ne 0 ]; then
echo "Syntax error detected."
FAIL=1
fi

########################################
# Validate required fields
########################################

grep -q "PLUGIN_NAME=" "$FILE" || { echo "Missing PLUGIN_NAME"; FAIL=1; }

grep -q "PLUGIN_DESCRIPTION=" "$FILE" || { echo "Missing PLUGIN_DESCRIPTION"; FAIL=1; }

grep -q "PLUGIN_CATEGORY=" "$FILE" || { echo "Missing PLUGIN_CATEGORY"; FAIL=1; }

grep -q "PLUGIN_DEPENDS=" "$FILE" || { echo "Missing PLUGIN_DEPENDS"; FAIL=1; }

grep -q "PLUGIN_PORTS=" "$FILE" || { echo "Missing PLUGIN_PORTS"; FAIL=1; }

grep -q "PLUGIN_HOST_NETWORK=" "$FILE" || { echo "Missing PLUGIN_HOST_NETWORK"; FAIL=1; }

grep -q "PLUGIN_DASHBOARD=" "$FILE" || { echo "Missing PLUGIN_DASHBOARD"; FAIL=1; }

########################################
# Validate install function
########################################

grep -q "install_service()" "$FILE" || { echo "Missing install_service()"; FAIL=1; }

echo ""

done

########################################
# Exit if failures occurred
########################################

if [ $FAIL -eq 1 ]; then

echo "Plugin validation failed."

exit 1

else

echo "All plugins passed validation."

fi