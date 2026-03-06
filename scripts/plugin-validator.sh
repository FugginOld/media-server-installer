#!/usr/bin/env bash

PLUGIN_DIR="./plugins"

echo ""
echo "==============================="
echo " Media Stack Plugin Validator"
echo "==============================="
echo ""

FAILURES=0

for FILE in $(find $PLUGIN_DIR -name "*.sh")
do

echo "Checking $FILE"

########################################
# Syntax check
########################################

bash -n "$FILE"

if [ $? -ne 0 ]; then
echo "❌ Syntax error"
FAILURES=$((FAILURES+1))
continue
fi

########################################
# Required variables
########################################

grep -q "PLUGIN_NAME" "$FILE" || echo "Missing PLUGIN_NAME"
grep -q "PLUGIN_DESCRIPTION" "$FILE" || echo "Missing description"
grep -q "install_service()" "$FILE" || echo "Missing install function"

########################################
# Registry check
########################################

grep -q "register_service" "$FILE" || echo "Missing registry call"

echo "✔ OK"

echo ""

done

echo "Validation complete"

if [ $FAILURES -gt 0 ]; then
echo "$FAILURES plugins failed validation"
exit 1
fi