#!/usr/bin/env bash
# Run the full test suite using bats.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

########################################
# Preflight dependency checks
########################################

REQUIRED_COMMANDS=(bats jq python3 ss)
MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if [ "${#MISSING_COMMANDS[@]}" -ne 0 ]; then
    echo "The test suite requires the following commands to be installed: ${MISSING_COMMANDS[*]}"
    echo "Please install them and re-run the tests."
    exit 1
fi

echo ""
echo "================================"
echo "Running Media Stack Test Suite"
echo "================================"
echo ""

bats "$SCRIPT_DIR"/*.bats "$@"
