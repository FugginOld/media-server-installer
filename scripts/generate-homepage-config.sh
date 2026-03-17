#!/usr/bin/env bash
set -euo pipefail

########################################
# Resolve installer directory
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

########################################
# Delegate to dashboard generator
########################################

exec bash "$INSTALL_DIR/scripts/dashboard-generator.sh"
