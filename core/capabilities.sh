#!/usr/bin/env bash

########################################
# Load runtime if not already loaded
########################################

if [ -z "${MEDIA_STACK_RUNTIME_LOADED:-}" ]; then
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INSTALL_DIR="$SCRIPT_DIR"
source "$INSTALL_DIR/lib/runtime.sh"
fi

########################################
# System Capability Detection
########################################

CAP_GPU="none"
CAP_FS="unknown"
CAP_CONTAINER="unknown"

########################################
# Detect GPU Capability
########################################

detect_gpu_capability() {

if command -v nvidia-smi >/dev/null 2>&1; then

CAP_GPU="nvidia"

elif command -v lspci >/dev/null 2>&1; then

if lspci | grep -qi 'intel.*\(vga\|graphics\)'; then
CAP_GPU="intel"

elif lspci | grep -qi 'amd.*\(vga\|graphics\)'; then
CAP_GPU="amd"

else
CAP_GPU="none"
fi

else

CAP_GPU="none"

fi

}

########################################
# Detect Filesystem Capability
########################################

detect_fs_capability() {

ROOT_FS="$(df -T / | awk 'NR==2 {print $2}')"

case "$ROOT_FS" in

zfs)
CAP_FS="zfs"
;;

btrfs)
CAP_FS="btrfs"
;;

ext4|ext3|ext2)
CAP_FS="ext"
;;

xfs)
CAP_FS="xfs"
;;

*)
CAP_FS="$ROOT_FS"
;;

esac

}

########################################
# Detect Container Runtime
########################################

detect_container_runtime() {

if command -v docker >/dev/null 2>&1; then

CAP_CONTAINER="docker"

elif command -v podman >/dev/null 2>&1; then

CAP_CONTAINER="podman"

else

CAP_CONTAINER="none"

fi

}

########################################
# Detect All Capabilities
########################################

detect_capabilities() {

echo ""
echo "Detecting system capabilities..."

detect_gpu_capability
detect_fs_capability
detect_container_runtime

echo "GPU: $CAP_GPU"
echo "Filesystem: $CAP_FS"
echo "Container runtime: $CAP_CONTAINER"
echo ""

export CAP_GPU
export CAP_FS
export CAP_CONTAINER

}

########################################
# Export functions
########################################

export -f detect_capabilities
export -f detect_gpu_capability
export -f detect_fs_capability
export -f detect_container_runtime