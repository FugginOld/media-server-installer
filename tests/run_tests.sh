#!/usr/bin/env bash
# Run the full test suite using bats.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v bats >/dev/null 2>&1; then
    echo "bats is required to run tests. Install with: sudo apt-get install bats"
    exit 1
fi

echo ""
echo "================================"
echo "Running Media Stack Test Suite"
echo "================================"
echo ""

bats "$SCRIPT_DIR"/*.bats "$@"
