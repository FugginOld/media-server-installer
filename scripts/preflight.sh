#!/usr/bin/env bash
set -euo pipefail

########################################
# Resolve installer directory
########################################

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="${INSTALL_DIR:-$SCRIPT_ROOT}"

########################################
# Load runtime
########################################

source "$INSTALL_DIR/lib/runtime.sh"

########################################
# Load required core modules
########################################

source "$CORE_DIR/platform.sh"
source "$CORE_DIR/capabilities.sh"
source "$CORE_DIR/hardware.sh"
source "$CORE_DIR/docker.sh"
source "$CORE_DIR/directories.sh"

########################################
# Media Stack Preflight Checks
########################################

echo ""
echo "================================"
echo "Media Stack Preflight Checks"
echo "================================"
echo ""

########################################
# Ensure running as root
########################################

if [[ "$EUID" -ne 0 ]]; then
    echo "Installer must be run as root."
    exit 1
fi

echo "Running as root: OK"

########################################
# Detect operating system
########################################

detect_platform

########################################
# CPU architecture
########################################

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64|amd64|aarch64|arm64)
        echo "Supported architecture: $ARCH"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

########################################
# Internet connectivity
########################################

echo "Checking internet connectivity..."

if curl -fsSL https://github.com >/dev/null 2>&1; then
    echo "Internet connectivity: OK"
else
    echo "Internet connection failed."
    exit 1
fi

########################################
# Required commands
########################################

REQUIRED_CMDS=(
    curl
    git
    jq
    lspci
)

MISSING=()

for CMD in "${REQUIRED_CMDS[@]}"; do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "$CMD installed"
    else
        echo "$CMD missing"
        MISSING+=("$CMD")
    fi
done

########################################
# Install missing dependencies
########################################

if [[ "${#MISSING[@]}" -gt 0 ]]; then

    echo ""
    echo "Installing missing dependencies..."
    echo ""

    pkg_update

    for PKG in "${MISSING[@]}"; do
        pkg_install "$PKG"
    done

fi

########################################
# Docker check
########################################

if command -v docker >/dev/null 2>&1; then
    echo "Docker detected"

    if docker compose version >/dev/null 2>&1; then
        echo "Docker Compose detected"
    else
        echo "Docker Compose missing (will be installed later)"
    fi

else
    echo "Docker not installed (will be installed later)"
fi

########################################
# Disk space check
########################################

FREE_KB="$(df / | awk 'NR==2 {print $4}')"
FREE_GB=$((FREE_KB / 1024 / 1024))

if [[ "$FREE_KB" -lt 1048576 ]]; then
    echo "Less than 1GB free disk space."
    exit 1
fi

echo "Disk space available: ${FREE_GB}GB"

echo ""
echo "Preflight checks passed."
echo ""