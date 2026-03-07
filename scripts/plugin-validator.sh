#!/usr/bin/env bash

PLUGIN_DIR="./plugins"

echo ""
echo "================================"
echo " Plugin Validation"
echo "================================"
echo ""

FAIL=0

for FILE in $(find "$PLUGIN_DIR" -name "*.sh")
do

echo "Checking $FILE"

########################################
# Syntax check
########################################

bash -n "$FILE"

if [ $? -ne 0 ]; then
    echo "Syntax error"
    FAIL=1
fi

########################################
# Required metadata
########################################

grep -q "PLUGIN_NAME=" "$FILE" || { echo "Missing PLUGIN_NAME"; FAIL=1; }

grep -q "PLUGIN_DESCRIPTION=" "$FILE" || { echo "Missing PLUGIN_DESCRIPTION"; FAIL=1; }

grep -q "PLUGIN_CATEGORY=" "$FILE" || { echo "Missing PLUGIN_CATEGORY"; FAIL=1; }

grep -q "PLUGIN_DEPENDS=" "$FILE" || { echo "Missing PLUGIN_DEPENDS"; FAIL=1; }

grep -q "PLUGIN_DASHBOARD=" "$FILE" || { echo "Missing PLUGIN_DASHBOARD"; FAIL=1; }

grep -q "PLUGIN_PORTS=" "$FILE" || { echo "Missing PLUGIN_PORTS"; FAIL=1; }

grep -q "PLUGIN_HOST_NETWORK=" "$FILE" || { echo "Missing PLUGIN_HOST_NETWORK"; FAIL=1; }

########################################
# Required install function
########################################

grep -q "install_service()" "$FILE" || { echo "Missing install_service()"; FAIL=1; }

########################################
# Dashboard check
########################################

if grep -q "PLUGIN_DASHBOARD=true" "$FILE"; then

    grep -q "register_service" "$FILE" || { echo "Dashboard plugin missing register_service"; FAIL=1; }

fi

echo ""

done

########################################
# Final result
########################################

if [ $FAIL -eq 1 ]; then

echo "Plugin validation FAILED"
exit 1

else

echo "All plugins passed validation."

fi