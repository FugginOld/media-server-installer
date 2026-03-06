#!/usr/bin/env bash

PLUGIN_DIR="./plugins"

echo ""
echo "Plugin Validation"
echo ""

FAIL=0

for FILE in $(find $PLUGIN_DIR -name "*.sh")
do

echo "Checking $FILE"

bash -n "$FILE"

if [ $? -ne 0 ]; then
echo "Syntax error"
FAIL=1
fi

grep -q "PLUGIN_NAME" "$FILE" || echo "Missing PLUGIN_NAME"
grep -q "install_service()" "$FILE" || echo "Missing install_service"
grep -q "register_service" "$FILE" || echo "Missing registry call"

echo ""

done

if [ $FAIL -eq 1 ]; then
exit 1
fi