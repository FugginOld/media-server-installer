#!/usr/bin/env bash

echo ""
echo "================================"
echo " Media Stack Preflight Checks"
echo "================================"
echo ""

########################################
# Root check
########################################

if [ "$EUID" -ne 0 ]; then
    echo "Installer must be run as root."
    exit 1
fi

echo "Running as root: OK"

########################################
# OS check
########################################

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot detect operating system."
    exit 1
fi

case "$ID" in
debian|devuan|ubuntu)
    echo "Supported OS detected: $ID"
    ;;
*)
    echo "Unsupported OS: $ID"
    exit 1
    ;;
esac

########################################
# Internet connectivity
########################################

echo "Checking internet connectivity..."

if ping -c 1 github.com >/dev/null 2>&1; then
    echo "Internet connectivity: OK"
else
    echo "No internet connection detected."
    exit 1
fi

########################################
# Required tools
########################################

REQUIRED_CMDS=(curl git jq)

for CMD in "${REQUIRED_CMDS[@]}"
do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "$CMD installed"
    else
        echo "$CMD missing — installing..."

        if command -v apt >/dev/null 2>&1; then
            apt update
            apt install -y "$CMD"
        else
            echo "Cannot install $CMD automatically."
            exit 1
        fi
    fi
done

########################################
# Disk space check
########################################

FREE_SPACE=$(df / | awk 'NR==2 {print $4}')

if [ "$FREE_SPACE" -lt 1048576 ]; then
    echo "Less than 1GB free disk space."
    exit 1
fi

echo "Disk space check: OK"

echo ""
echo "Preflight checks passed."
echo ""