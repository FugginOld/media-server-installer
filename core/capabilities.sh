#!/usr/bin/env bash

########################################
# Capability Detection
########################################

CAP_GPU="none"
CAP_CONTAINER_RUNTIME="unknown"
CAP_FILESYSTEM="unknown"

detect_capabilities() {

echo ""
echo "Detecting system capabilities..."

########################################
# Detect GPU
########################################

if command -v nvidia-smi >/dev/null 2>&1; then
CAP_GPU="nvidia"

elif lspci 2>/dev/null | grep -qi "intel.*vga"; then
CAP_GPU="intel"

elif lspci 2>/dev/null | grep -qi "amd.*vga"; then
CAP_GPU="amd"

else
CAP_GPU="none"
fi

########################################
# Detect container runtime
########################################

if command -v docker >/dev/null 2>&1; then
CAP_CONTAINER_RUNTIME="docker"

elif command -v podman >/dev/null 2>&1; then
CAP_CONTAINER_RUNTIME="podman"

else
CAP_CONTAINER_RUNTIME="none"
fi

########################################
# Detect filesystem
########################################

ROOT_FS=$(df -T / 2>/dev/null | awk 'NR==2 {print $2}')

case "$ROOT_FS" in
ext4)
CAP_FILESYSTEM="ext4"
;;
btrfs)
CAP_FILESYSTEM="btrfs"
;;
zfs)
CAP_FILESYSTEM="zfs"
;;
xfs)
CAP_FILESYSTEM="xfs"
;;
*)
CAP_FILESYSTEM="$ROOT_FS"
;;
esac

########################################
# Output results
########################################

echo "GPU: $CAP_GPU"
echo "Filesystem: $CAP_FILESYSTEM"
echo "Container runtime: $CAP_CONTAINER_RUNTIME"

echo ""

}

########################################
# Export variables
########################################

export CAP_GPU
export CAP_CONTAINER_RUNTIME
export CAP_FILESYSTEM

export -f detect_capabilities
