#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/../../core/runtime.sh" 2>/dev/null || \
source "$SCRIPT_DIR/core/runtime.sh"

# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export INSTALL_DIR
export SCRIPTS_DIR="$INSTALL_DIR/scripts"
export PLUGINS_DIR="$INSTALL_DIR/plugins"
export CORE_DIR="$INSTALL_DIR/core"
export TEMPLATES_DIR="$INSTALL_DIR/templates"
